# frozen_string_literal: true

module Ci
  class ProcessBuildService < BaseService
    def execute(build, current_status)
      if valid_statuses_for_build(build).include?(current_status)
        process(build)
        true
      else
        build.skip
        false
      end
    end

    private

    def process(build)
      if build.schedulable?
        build.schedule
      elsif build.action?
        build.actionize
      else
        enqueue(build)
      end
    end

    def enqueue(build)
      return build.drop!(:failed_outdated_deployment_job) if build.prevent_rollback_deployment?

      build.enqueue
    end

    def valid_statuses_for_build(build)
      case build.when
      when 'on_success', 'manual', 'delayed'
        build.scheduling_type_dag? ? %w[success] : %w[success skipped]
      when 'on_failure'
        %w[failed]
      when 'always'
        %w[success failed skipped]
      else
        []
      end
    end
  end
end

Ci::ProcessBuildService.prepend_mod_with('Ci::ProcessBuildService')
