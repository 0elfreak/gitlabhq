import { __, s__, n__ } from '~/locale';

export const JOB_STATUS_GROUP_SUCCESS = 'success';

export const STATUS_BADGE_VARIANTS = {
  success: 'success',
  passed: 'success',
  error: 'danger',
  failed: 'danger',
  pending: 'warning',
  'waiting-for-resource': 'warning',
  'failed-with-warnings': 'warning',
  'success-with-warnings': 'warning',
  running: 'info',
  canceled: 'neutral',
  disabled: 'neutral',
  scheduled: 'neutral',
  manual: 'neutral',
  notification: 'muted',
  preparing: 'muted',
  created: 'muted',
  skipped: 'muted',
  notfound: 'muted',
};

export const I18N_DOWNLOAD = __('Download');
export const I18N_BROWSE = s__('Artifacts|Browse');
export const I18N_DELETE = __('Delete');
export const I18N_EXPIRED = __('Expired');
export const I18N_DESTROY_ERROR = s__('Artifacts|An error occurred while deleting the artifact');
export const I18N_FETCH_ERROR = s__('Artifacts|An error occurred while retrieving job artifacts');
export const I18N_ARTIFACTS = __('Artifacts');
export const I18N_JOB = __('Job');
export const I18N_SIZE = __('Size');
export const I18N_CREATED = __('Created');
export const I18N_ARTIFACTS_COUNT = (count) => n__('%d file', '%d files', count);

export const INITIAL_CURRENT_PAGE = 1;
export const INITIAL_PREVIOUS_PAGE_CURSOR = '';
export const INITIAL_NEXT_PAGE_CURSOR = '';
export const JOBS_PER_PAGE = 20;
export const INITIAL_LAST_PAGE_SIZE = null;

export const ARCHIVE_FILE_TYPE = 'ARCHIVE';

export const ARTIFACT_ROW_HEIGHT = 56;
export const ARTIFACTS_SHOWN_WITHOUT_SCROLLING = 4;
