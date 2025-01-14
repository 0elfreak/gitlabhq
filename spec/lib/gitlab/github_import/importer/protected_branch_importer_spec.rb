# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::ProtectedBranchImporter do
  subject(:importer) { described_class.new(github_protected_branch, project, client) }

  let(:branch_name) { 'protection' }
  let(:allow_force_pushes_on_github) { true }
  let(:required_conversation_resolution) { false }
  let(:required_signatures) { false }
  let(:required_pull_request_reviews) { false }
  let(:expected_push_access_level) { Gitlab::Access::MAINTAINER }
  let(:expected_merge_access_level) { Gitlab::Access::MAINTAINER }
  let(:expected_allow_force_push) { true }
  let(:github_protected_branch) do
    Gitlab::GithubImport::Representation::ProtectedBranch.new(
      id: branch_name,
      allow_force_pushes: allow_force_pushes_on_github,
      required_conversation_resolution: required_conversation_resolution,
      required_signatures: required_signatures,
      required_pull_request_reviews: required_pull_request_reviews
    )
  end

  let(:project) { create(:project, :repository) }
  let(:client) { instance_double('Gitlab::GithubImport::Client') }

  describe '#execute' do
    let(:create_service) { instance_double('ProtectedBranches::CreateService') }

    shared_examples 'create branch protection by the strictest ruleset' do
      let(:expected_ruleset) do
        {
          name: 'protection',
          push_access_levels_attributes: [{ access_level: expected_push_access_level }],
          merge_access_levels_attributes: [{ access_level: expected_merge_access_level }],
          allow_force_push: expected_allow_force_push
        }
      end

      it 'calls service with the correct arguments' do
        expect(ProtectedBranches::CreateService).to receive(:new).with(
          project,
          project.creator,
          expected_ruleset
        ).and_return(create_service)

        expect(create_service).to receive(:execute).with(skip_authorization: true)
        importer.execute
      end

      it 'creates protected branch and access levels for given github rule' do
        expect { importer.execute }.to change(ProtectedBranch, :count).by(1)
          .and change(ProtectedBranch::PushAccessLevel, :count).by(1)
          .and change(ProtectedBranch::MergeAccessLevel, :count).by(1)
      end
    end

    shared_examples 'does not change project attributes' do
      it 'does not change only_allow_merge_if_all_discussions_are_resolved' do
        expect { importer.execute }.not_to change(project, :only_allow_merge_if_all_discussions_are_resolved)
      end

      it 'does not change push_rule for the project' do
        expect(project).not_to receive(:push_rule)

        importer.execute
      end
    end

    context 'when branch is protected on GitLab' do
      before do
        create(
          :protected_branch,
          project: project,
          name: 'protect*',
          allow_force_push: allow_force_pushes_on_gitlab
        )
      end

      context 'when branch protection rule on Gitlab is stricter than on Github' do
        let(:allow_force_pushes_on_github) { true }
        let(:allow_force_pushes_on_gitlab) { false }
        let(:expected_allow_force_push) { false }

        it_behaves_like 'create branch protection by the strictest ruleset'
      end

      context 'when branch protection rule on Github is stricter than on Gitlab' do
        let(:allow_force_pushes_on_github) { false }
        let(:allow_force_pushes_on_gitlab) { true }
        let(:expected_allow_force_push) { false }

        it_behaves_like 'create branch protection by the strictest ruleset'
      end

      context 'when branch protection rules on Github and Gitlab are the same' do
        let(:allow_force_pushes_on_github) { true }
        let(:allow_force_pushes_on_gitlab) { true }
        let(:expected_allow_force_push) { true }

        it_behaves_like 'create branch protection by the strictest ruleset'
      end
    end

    context 'when branch is not protected on GitLab' do
      let(:expected_allow_force_push) { true }

      it_behaves_like 'create branch protection by the strictest ruleset'
    end

    context "when branch is default" do
      before do
        allow(project).to receive(:default_branch).and_return(branch_name)
      end

      context 'when required_conversation_resolution rule is enabled' do
        let(:required_conversation_resolution) { true }

        it 'changes project settings' do
          expect { importer.execute }.to change(project, :only_allow_merge_if_all_discussions_are_resolved).to(true)
        end
      end

      context 'when required_conversation_resolution rule is disabled' do
        let(:required_conversation_resolution) { false }

        it_behaves_like 'does not change project attributes'
      end

      context 'when required_signatures rule is enabled' do
        let(:required_signatures) { true }
        let(:push_rules_feature_available?) { true }

        before do
          stub_licensed_features(push_rules: push_rules_feature_available?)
        end

        context 'when the push_rules feature is available', if: Gitlab.ee? do
          context 'when project push_rules did previously exist' do
            before do
              create(:push_rule, project: project)
            end

            it 'updates push_rule reject_unsigned_commits attribute' do
              expect { importer.execute }.to change { project.reload.push_rule.reject_unsigned_commits }.to(true)
            end
          end

          context 'when project push_rules did not previously exist' do
            it 'creates project push_rule with the enabled reject_unsigned_commits attribute' do
              expect { importer.execute }.to change(project, :push_rule).from(nil)
              expect(project.push_rule.reject_unsigned_commits).to be_truthy
            end
          end
        end

        context 'when the push_rules feature is not available' do
          let(:push_rules_feature_available?) { false }

          it_behaves_like 'does not change project attributes'
        end
      end

      context 'when required_signatures rule is disabled' do
        let(:required_signatures) { false }

        it_behaves_like 'does not change project attributes'
      end
    end

    context 'when branch is not default' do
      context 'when required_conversation_resolution rule is enabled' do
        let(:required_conversation_resolution) { true }

        it_behaves_like 'does not change project attributes'
      end

      context 'when required_conversation_resolution rule is disabled' do
        let(:required_conversation_resolution) { false }

        it_behaves_like 'does not change project attributes'
      end

      context 'when required_signatures rule is enabled' do
        let(:required_signatures) { true }

        it_behaves_like 'does not change project attributes'
      end

      context 'when required_signatures rule is disabled' do
        let(:required_signatures) { false }

        it_behaves_like 'does not change project attributes'
      end
    end

    context 'when required_pull_request_reviews rule is enabled on GitHub' do
      let(:required_pull_request_reviews) { true }
      let(:expected_push_access_level) { Gitlab::Access::NO_ACCESS }
      let(:expected_merge_access_level) { Gitlab::Access::MAINTAINER }

      it_behaves_like 'create branch protection by the strictest ruleset'
    end

    context 'when required_pull_request_reviews rule is disabled on GitHub' do
      let(:required_pull_request_reviews) { false }

      context 'when branch is default' do
        before do
          allow(project).to receive(:default_branch).and_return(branch_name)
        end

        context 'when default branch protection = Gitlab::Access::PROTECTION_DEV_CAN_PUSH' do
          before do
            stub_application_setting(default_branch_protection: Gitlab::Access::PROTECTION_DEV_CAN_PUSH)
          end

          let(:expected_push_access_level) { Gitlab::Access::DEVELOPER }
          let(:expected_merge_access_level) { Gitlab::Access::MAINTAINER }

          it_behaves_like 'create branch protection by the strictest ruleset'
        end

        context 'when default branch protection = Gitlab::Access::PROTECTION_DEV_CAN_MERGE' do
          before do
            stub_application_setting(default_branch_protection: Gitlab::Access::PROTECTION_DEV_CAN_MERGE)
          end

          let(:expected_push_access_level) { Gitlab::Access::MAINTAINER }
          let(:expected_merge_access_level) { Gitlab::Access::DEVELOPER }

          it_behaves_like 'create branch protection by the strictest ruleset'
        end
      end

      context 'when branch is protected on GitLab' do
        let(:protected_branch) do
          create(
            :protected_branch,
            project: project,
            name: 'protect*',
            allow_force_push: true
          )
        end

        let(:push_access_level) { protected_branch.push_access_levels.first }
        let(:merge_access_level) { protected_branch.merge_access_levels.first }

        context 'when there is branch protection rule for the role' do
          context 'when No one can merge' do
            before do
              merge_access_level.update_column(:access_level, Gitlab::Access::NO_ACCESS)
            end

            let(:expected_push_access_level) { push_access_level.access_level }
            let(:expected_merge_access_level) { Gitlab::Access::NO_ACCESS }

            it_behaves_like 'create branch protection by the strictest ruleset'
          end

          context 'when Maintainers and Developers can merge' do
            before do
              merge_access_level.update_column(:access_level, Gitlab::Access::DEVELOPER)
            end

            let(:gitlab_push_access_level) { push_access_level.access_level }
            let(:gitlab_merge_access_level) { merge_access_level.access_level }
            let(:expected_push_access_level) { gitlab_push_access_level }
            let(:expected_merge_access_level) { [gitlab_merge_access_level, github_default_merge_access_level].max }
            let(:github_default_merge_access_level) do
              Gitlab::GithubImport::Importer::ProtectedBranchImporter::GITHUB_DEFAULT_MERGE_ACCESS_LEVEL
            end

            it_behaves_like 'create branch protection by the strictest ruleset'
          end
        end

        context 'when there is no branch protection rule for the role' do
          before do
            push_access_level.update_column(:user_id, project.owner.id)
            merge_access_level.update_column(:user_id, project.owner.id)
          end

          let(:expected_push_access_level) { ProtectedBranch::PushAccessLevel::GITLAB_DEFAULT_ACCESS_LEVEL }
          let(:expected_merge_access_level) { Gitlab::Access::MAINTAINER }

          it_behaves_like 'create branch protection by the strictest ruleset'
        end
      end

      context 'when branch is neither default nor protected on GitLab' do
        let(:expected_push_access_level) { ProtectedBranch::PushAccessLevel::GITLAB_DEFAULT_ACCESS_LEVEL }
        let(:expected_merge_access_level) { ProtectedBranch::MergeAccessLevel::GITLAB_DEFAULT_ACCESS_LEVEL }

        it_behaves_like 'create branch protection by the strictest ruleset'
      end
    end
  end
end
