# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Settings > User changes default branch' do
  let(:user) { create(:user) }

  before do
    sign_in(user)

    visit project_settings_repository_path(project)
  end

  context 'with normal project' do
    let(:project) { create(:project, :repository, namespace: user.namespace) }

    it 'allows to change the default branch', :js do
      dropdown_selector = '[data-testid="default-branch-dropdown"]'
      # Otherwise, running JS may overwrite our change to project_default_branch
      wait_for_requests

      expect(page).to have_selector(dropdown_selector)
      find(dropdown_selector).click

      fill_in 'Search branch', with: 'fix'
      click_button 'fix'

      page.within '#default-branch-settings' do
        click_button 'Save changes'
      end

      expect(find("#{dropdown_selector} input", visible: false).value).to eq 'fix'
    end
  end

  context 'with empty project' do
    let(:project) { create(:project_empty_repo, namespace: user.namespace) }

    it 'does not show default branch selector' do
      expect(page).not_to have_selector('[data-testid="default-branch-dropdown"]')
    end
  end
end
