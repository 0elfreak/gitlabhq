# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RunPipelineScheduleWorker do
  describe '#perform' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, namespace: group) }
    let_it_be(:user) { create(:user) }
    let_it_be(:pipeline_schedule) { create(:ci_pipeline_schedule, :nightly, project: project ) }

    let(:worker) { described_class.new }

    context 'when a schedule not found' do
      it 'does not call the Service' do
        expect(Ci::CreatePipelineService).not_to receive(:new)
        expect(worker).not_to receive(:run_pipeline_schedule)

        worker.perform(non_existing_record_id, user.id)
      end
    end

    context 'when a schedule project is missing' do
      before do
        project.delete
      end

      it 'does not call the Service' do
        expect(Ci::CreatePipelineService).not_to receive(:new)
        expect(worker).not_to receive(:run_pipeline_schedule)

        worker.perform(pipeline_schedule.id, user.id)
      end
    end

    context 'when a user not found' do
      it 'does not call the Service' do
        expect(Ci::CreatePipelineService).not_to receive(:new)
        expect(worker).not_to receive(:run_pipeline_schedule)

        worker.perform(pipeline_schedule.id, non_existing_record_id)
      end
    end

    context 'when everything is ok' do
      let(:create_pipeline_service) { instance_double(Ci::CreatePipelineService) }

      it 'calls the Service' do
        expect(Ci::CreatePipelineService).to receive(:new).with(project, user, ref: pipeline_schedule.ref).and_return(create_pipeline_service)
        expect(create_pipeline_service).to receive(:execute!).with(:schedule, ignore_skip_ci: true, save_on_errors: false, schedule: pipeline_schedule)

        worker.perform(pipeline_schedule.id, user.id)
      end
    end

    context 'when database statement timeout happens' do
      before do
        allow(Ci::CreatePipelineService).to receive(:new) { raise ActiveRecord::StatementInvalid }

        expect(Gitlab::ErrorTracking)
          .to receive(:track_and_raise_for_dev_exception)
          .with(ActiveRecord::StatementInvalid,
                issue_url: 'https://gitlab.com/gitlab-org/gitlab-foss/issues/41231',
                schedule_id: pipeline_schedule.id).once
      end

      it 'increments Prometheus counter' do
        expect(Gitlab::Metrics)
          .to receive(:counter)
          .with(:pipeline_schedule_creation_failed_total, "Counter of failed attempts of pipeline schedule creation")
          .and_call_original

        worker.perform(pipeline_schedule.id, user.id)
      end

      it 'logging a pipeline error' do
        expect(Gitlab::AppLogger)
          .to receive(:error)
          .with(a_string_matching('ActiveRecord::StatementInvalid'))
          .and_call_original

        worker.perform(pipeline_schedule.id, user.id)
      end
    end

    context 'when pipeline cannot be created' do
      before do
        allow(Ci::CreatePipelineService).to receive(:new) { raise Ci::CreatePipelineService::CreateError }
      end

      it 'logging a pipeline error' do
        expect(worker)
          .to receive(:log_extra_metadata_on_done)
          .with(:pipeline_creation_error, an_instance_of(Ci::CreatePipelineService::CreateError))
          .and_call_original

        worker.perform(pipeline_schedule.id, user.id)
      end
    end
  end
end
