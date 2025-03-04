# frozen_string_literal: true

require 'pathname'

module Glfm
  module Constants
    # Root dir containing all specification files
    specification_path = Pathname.new(File.expand_path("../../../glfm_specification", __dir__))

    # GitHub Flavored Markdown specification file
    GHFM_SPEC_TXT_URI = 'https://raw.githubusercontent.com/github/cmark-gfm/master/test/spec.txt'
    GHFM_SPEC_VERSION = '0.29'
    GHFM_SPEC_MD_FILENAME = "ghfm_spec_v_#{GHFM_SPEC_VERSION}.md"
    GHFM_SPEC_MD_PATH = specification_path.join('input/github_flavored_markdown', GHFM_SPEC_MD_FILENAME)

    # GitLab Flavored Markdown specification files
    specification_input_glfm_path = specification_path.join('input/gitlab_flavored_markdown')
    GLFM_INTRO_MD_PATH = specification_input_glfm_path.join('glfm_intro.md')
    GLFM_OFFICIAL_SPECIFICATION_EXAMPLES_MD_PATH =
      specification_input_glfm_path.join('glfm_official_specification_examples.md')
    GLFM_INTERNAL_EXTENSION_EXAMPLES_MD_PATH = specification_input_glfm_path.join('glfm_internal_extension_examples.md')
    GLFM_EXAMPLE_STATUS_YML_PATH = specification_input_glfm_path.join('glfm_example_status.yml')
    GLFM_EXAMPLE_METADATA_YML_PATH =
      specification_input_glfm_path.join('glfm_example_metadata.yml')
    GLFM_EXAMPLE_NORMALIZATIONS_YML_PATH = specification_input_glfm_path.join('glfm_example_normalizations.yml')
    GLFM_SPEC_OUTPUT_PATH = specification_path.join('output')
    GLFM_SPEC_TXT_PATH = GLFM_SPEC_OUTPUT_PATH.join('spec.txt')
    GLFM_SPEC_HTML_PATH = GLFM_SPEC_OUTPUT_PATH.join('spec.html')

    # Example Snapshot (ES) files
    EXAMPLE_SNAPSHOTS_PATH = File.expand_path("../../../glfm_specification/example_snapshots", __dir__)
    ES_EXAMPLES_INDEX_YML_PATH = File.join(EXAMPLE_SNAPSHOTS_PATH, 'examples_index.yml')
    ES_MARKDOWN_YML_PATH = File.join(EXAMPLE_SNAPSHOTS_PATH, 'markdown.yml')
    ES_HTML_YML_PATH = File.join(EXAMPLE_SNAPSHOTS_PATH, 'html.yml')
    ES_PROSEMIRROR_JSON_YML_PATH = File.join(EXAMPLE_SNAPSHOTS_PATH, 'prosemirror_json.yml')

    # Other constants used for processing files
    GLFM_SPEC_TXT_HEADER = <<~MARKDOWN
      ---
      title: GitLab Flavored Markdown (GLFM) Spec
      version: alpha
      ...
    MARKDOWN
    INTRODUCTION_HEADER_LINE_TEXT = /\A# Introduction\Z/.freeze
    END_TESTS_COMMENT_LINE_TEXT = /\A<!-- END TESTS -->\Z/.freeze
    MARKDOWN_TEMPFILE_BASENAME = %w[MARKDOWN_TEMPFILE_ .yml].freeze
    METADATA_TEMPFILE_BASENAME = %w[METADATA_TEMPFILE_ .yml].freeze
    STATIC_HTML_TEMPFILE_BASENAME = %w[STATIC_HTML_TEMPFILE_ .yml].freeze
    WYSIWYG_HTML_AND_JSON_TEMPFILE_BASENAME = %w[WYSIWYG_HTML_AND_JSON_TEMPFILE_ .yml].freeze
  end
end
