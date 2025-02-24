# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/json'

RSpec.describe RuboCop::Cop::Gitlab::Json do
  context 'when ::JSON is called' do
    it 'registers an offense and autocorrects' do
      expect_offense(<<~RUBY)
        class Foo
          def bar
            JSON.parse('{ "foo": "bar" }')
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `Gitlab::Json` over calling `JSON` or `to_json` directly. [...]
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        class Foo
          def bar
            Gitlab::Json.parse('{ "foo": "bar" }')
          end
        end
      RUBY
    end
  end

  context 'when ActiveSupport::JSON is called' do
    it 'registers an offense and autocorrects' do
      expect_offense(<<~RUBY)
        class Foo
          def bar
            ActiveSupport::JSON.parse('{ "foo": "bar" }')
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `Gitlab::Json` over calling `JSON` or `to_json` directly. [...]
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        class Foo
          def bar
            Gitlab::Json.parse('{ "foo": "bar" }')
          end
        end
      RUBY
    end
  end

  context 'when .to_json is called' do
    it 'registers an offense and autocorrects' do
      expect_offense(<<~RUBY)
        class Foo
          def bar
            { foo: "bar" }.to_json
            ^^^^^^^^^^^^^^^^^^^^^^ Prefer `Gitlab::Json` over calling `JSON` or `to_json` directly. [...]
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        class Foo
          def bar
            Gitlab::Json.dump({ foo: "bar" })
          end
        end
      RUBY
    end
  end
end
