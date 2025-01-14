# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Slack do
  it_behaves_like Integrations::SlackMattermostNotifier, "Slack"

  describe '#execute' do
    let_it_be(:project) { create(:project, :repository, :wiki_repo) }
    let_it_be(:slack_integration) { create(:integrations_slack, branches_to_be_notified: 'all', project: project) }

    before do
      stub_request(:post, slack_integration.webhook)
    end

    it 'uses only known events', :aggregate_failures do
      described_class::SUPPORTED_EVENTS_FOR_USAGE_LOG.each do |action|
        expect(Gitlab::UsageDataCounters::HLLRedisCounter.known_event?("i_ecosystem_slack_service_#{action}_notification")).to be true
      end
    end

    context 'hook data includes a user object' do
      let_it_be(:user) { create_default(:user) }

      shared_examples 'increases the usage data counter' do |event_name|
        subject(:execute) { slack_integration.execute(data) }

        it 'increases the usage data counter' do
          expect(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event).with(event_name, values: user.id).and_call_original

          execute
        end

        it_behaves_like 'Snowplow event tracking' do
          let(:feature_flag_name) { :route_hll_to_snowplow_phase2 }
          let(:category) { 'Integrations::Slack' }
          let(:action) { 'perform_integrations_action' }
          let(:namespace) { project.namespace }
          let(:label) { 'redis_hll_counters.ecosystem.ecosystem_total_unique_counts_monthly' }
          let(:property) { event_name }
        end
      end

      context 'event is not supported for usage log' do
        let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

        let(:data) { Gitlab::DataBuilder::Pipeline.build(pipeline) }

        it 'does not increase the usage data counter' do
          expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event).with('i_ecosystem_slack_service_pipeline_notification', values: user.id)

          slack_integration.execute(data)
        end
      end

      context 'issue notification' do
        let_it_be(:issue) { create(:issue, project: project) }

        let(:data) { issue.to_hook_data(user) }

        it_behaves_like 'increases the usage data counter', 'i_ecosystem_slack_service_issue_notification'
      end

      context 'push notification' do
        let(:data) { Gitlab::DataBuilder::Push.build_sample(project, user) }

        it_behaves_like 'increases the usage data counter', 'i_ecosystem_slack_service_push_notification'
      end

      context 'deployment notification' do
        let_it_be(:deployment) { create(:deployment, project: project, user: user) }

        let(:data) { Gitlab::DataBuilder::Deployment.build(deployment, deployment.status, Time.current) }

        it_behaves_like 'increases the usage data counter', 'i_ecosystem_slack_service_deployment_notification'
      end

      context 'wiki_page notification' do
        let(:wiki_page) { create(:wiki_page, wiki: project.wiki, project: project, message: 'user created page: Awesome wiki_page') }

        let(:data) { Gitlab::DataBuilder::WikiPage.build(wiki_page, user, 'create') }

        before do
          # Skip this method that is not relevant to this test to prevent having
          # to update project which is frozen
          allow(project.wiki).to receive(:after_wiki_activity)
        end

        it_behaves_like 'increases the usage data counter', 'i_ecosystem_slack_service_wiki_page_notification'
      end

      context 'merge_request notification' do
        let_it_be(:merge_request) { create(:merge_request, source_project: project) }

        let(:data) { merge_request.to_hook_data(user) }

        it_behaves_like 'increases the usage data counter', 'i_ecosystem_slack_service_merge_request_notification'
      end

      context 'note notification' do
        let_it_be(:issue_note) { create(:note_on_issue, project: project, note: 'issue note') }

        let(:data) { Gitlab::DataBuilder::Note.build(issue_note, user) }

        it_behaves_like 'increases the usage data counter', 'i_ecosystem_slack_service_note_notification'
      end

      context 'tag_push notification' do
        let(:oldrev) { Gitlab::Git::BLANK_SHA }
        let(:newrev) { '8a2a6eb295bb170b34c24c76c49ed0e9b2eaf34b' } # gitlab-test: git rev-parse refs/tags/v1.1.0
        let(:ref) { 'refs/tags/v1.1.0' }
        let(:data) { Git::TagHooksService.new(project, user, change: { oldrev: oldrev, newrev: newrev, ref: ref }).send(:push_data) }

        it_behaves_like 'increases the usage data counter', 'i_ecosystem_slack_service_tag_push_notification'
      end

      context 'confidential note notification' do
        let_it_be(:confidential_issue_note) { create(:note_on_issue, project: project, note: 'issue note', confidential: true) }

        let(:data) { Gitlab::DataBuilder::Note.build(confidential_issue_note, user) }

        it_behaves_like 'increases the usage data counter', 'i_ecosystem_slack_service_confidential_note_notification'
      end

      context 'confidential issue notification' do
        let_it_be(:issue) { create(:issue, project: project, confidential: true) }

        let(:data) { issue.to_hook_data(user) }

        it_behaves_like 'increases the usage data counter', 'i_ecosystem_slack_service_confidential_issue_notification'
      end
    end

    context 'hook data does not include a user' do
      let(:data) { Gitlab::DataBuilder::Pipeline.build(create(:ci_pipeline, project: project)) }

      it 'does not increase the usage data counter' do
        expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

        slack_integration.execute(data)
      end
    end
  end
end
