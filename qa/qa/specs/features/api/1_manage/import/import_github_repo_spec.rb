# frozen_string_literal: true

module QA
  # Spec uses real github.com, which means outage of github.com can actually block deployment
  # Keep spec in reliable bucket but don't run in blocking pipelines
  #
  # https://github.com/gitlab-qa-github/import-test <- project under test
  RSpec.describe 'Manage', :github, :reliable, :skip_live_env, :requires_admin, product_group: :import do
    describe 'Project import', issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/353583' do
      let!(:api_client) { Runtime::API::Client.as_admin }
      let!(:group) { Resource::Group.fabricate_via_api! { |resource| resource.api_client = api_client } }
      let!(:user) do
        Resource::User.fabricate_via_api! do |resource|
          resource.api_client = api_client
          resource.hard_delete_on_api_removal = true
        end
      end

      let!(:user_api_client) { Runtime::API::Client.new(user: user) }

      let(:imported_project) do
        Resource::ProjectImportedFromGithub.fabricate_via_api! do |project|
          project.name = 'imported-project'
          project.group = group
          project.github_personal_access_token = Runtime::Env.github_access_token
          project.github_repository_path = 'gitlab-qa-github/import-test'
          project.api_client = user_api_client
          project.issue_events_import = true
          project.full_notes_import = true
        end
      end

      before do
        group.add_member(user, Resource::Members::AccessLevel::MAINTAINER)
      end

      after do
        user.remove_via_api!
      end

      it 'imports Github repo via api', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347670' do
        imported_project.reload! # import the project

        expect { imported_project.project_import_status[:import_status] }.to eventually_eq('finished')
          .within(max_duration: 240, sleep_interval: 1)

        aggregate_failures do
          verify_status_data
          verify_repository_import
          verify_protected_branches_import
          verify_commits_import
          verify_labels_import
          verify_issues_import
          verify_milestones_import
          verify_wikis_import
          verify_merge_requests_import
          verify_release_import
        end
      end

      def verify_status_data
        stats = imported_project.project_import_status.dig(:stats, :imported)
        expect(stats).to include(
          issue: 1,
          label: 9,
          milestone: 1,
          note: 3,
          pull_request: 1,
          pull_request_review: 1,
          diff_note: 1,
          release: 1
        )
      end

      def verify_repository_import
        expect(imported_project.reload!.description).to eq('Project for github import test')
        expect(imported_project.api_response[:import_error]).to be_nil
      end

      def verify_protected_branches_import
        branches = imported_project.protected_branches.map do |branch|
          branch.slice(:name, :allow_force_push, :code_owner_approval_required)
        end
        expect(branches.first).to include(
          {
            name: 'main'
            # TODO: Add validation once https://gitlab.com/groups/gitlab-org/-/epics/8585 is closed
            # At the moment both options are always set to false regardless of state in github
            # allow_force_push: true,
            # code_owner_approval_required: true
          }
        )
      end

      def verify_commits_import
        expect(imported_project.commits.length).to eq(2)
      end

      def verify_labels_import
        labels = imported_project.labels.map { |label| label.slice(:name, :color) }

        expect(labels).to include(
          { name: 'bug', color: '#d73a4a' },
          { name: 'documentation', color: '#0075ca' },
          { name: 'duplicate', color: '#cfd3d7' },
          { name: 'enhancement', color: '#a2eeef' },
          { name: 'good first issue', color: '#7057ff' },
          { name: 'help wanted', color: '#008672' },
          { name: 'invalid', color: '#e4e669' },
          { name: 'question', color: '#d876e3' },
          { name: 'wontfix', color: '#ffffff' }
        )
      end

      def verify_milestones_import
        milestones = imported_project.milestones

        expect(milestones.length).to eq(1)
        expect(milestones.first).to include(title: '0.0.1', description: nil, state: 'active')
      end

      def verify_wikis_import
        wikis = imported_project.wikis

        expect(wikis.length).to eq(1)
        expect(wikis.first).to include(title: 'Home', format: 'markdown')
      end

      def verify_issues_import
        issues = imported_project.issues
        issue = Resource::Issue.init do |resource|
          resource.project = imported_project
          resource.iid = issues.first[:iid]
          resource.api_client = user_api_client
        end.reload!
        comments, events = fetch_events_and_comments(issue)

        expect(issues.length).to eq(1)
        expect(issue.api_resource).to include(
          title: 'Test issue',
          description: "*Created by: gitlab-qa-github*\n\nTest issue description",
          labels: ['good first issue', 'help wanted', 'question']
        )
        expect(comments).to match_array(
          [
            "*Created by: gitlab-qa-github*\n\nSome test comment",
            "*Created by: gitlab-qa-github*\n\nAnother test comment"
          ]
        )
        expect(events).to match_array(
          [
            { name: "add_label", label: "question" },
            { name: "add_label", label: "good first issue" },
            { name: "add_label", label: "help wanted" },
            { name: "add_milestone", label: "0.0.1" },
            { name: "closed" },
            { name: "reopened" }
          ]
        )
      end

      def verify_merge_requests_import
        merge_requests = imported_project.merge_requests
        merge_request = Resource::MergeRequest.init do |mr|
          mr.project = imported_project
          mr.iid = merge_requests.first[:iid]
          mr.api_client = user_api_client
        end.reload!
        comments, events = fetch_events_and_comments(merge_request)

        expect(merge_requests.length).to eq(1)
        expect(merge_request.api_resource).to include(
          title: 'Test pull request',
          state: 'opened',
          target_branch: 'main',
          source_branch: 'gitlab-qa-github-patch-1',
          labels: %w[documentation],
          description: "*Created by: gitlab-qa-github*\n\nTest pull request body"
        )
        expect(comments).to match_array(
          [
            "*Created by: gitlab-qa-github*\n\n**Review:** Commented\n\nGood but needs some improvement",
            "*Created by: gitlab-qa-github*\n\n```suggestion:-0+0\nProject for GitHub import test to GitLab\r\n```",
            "*Created by: gitlab-qa-github*\n\nSome test PR comment"
          ]
        )
        expect(events).to match_array(
          [
            { name: "add_label", label: "documentation" },
            { name: "add_milestone", label: "0.0.1" }
          ]
        )
      end

      def verify_release_import
        releases = imported_project.releases

        expect(releases.length).to eq(1)
        expect(releases.first).to include(
          tag_name: "0.0.1",
          name: "0.0.1",
          description: "Initial release",
          created_at: "2022-03-07T07:59:22.000Z",
          released_at: "2022-03-07T08:02:09.000Z"
        )
      end

      # Fetch events and comments from issue or mr
      #
      # @param [QA::Resource::Issuable] issuable
      # @return [Array]
      def fetch_events_and_comments(issuable)
        comments = issuable.comments.map { |comment| comment[:body] }
        events = [
          *issuable.label_events.map { |e| { name: "#{e[:action]}_label", label: e.dig(:label, :name) } },
          *issuable.state_events.map { |e| { name: e[:state] } },
          *issuable.milestone_events.map { |e| { name: "#{e[:action]}_milestone", label: e.dig(:milestone, :title) } }
        ]

        [comments, events]
      end
    end
  end
end
