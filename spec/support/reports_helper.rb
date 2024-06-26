# frozen_string_literal: true

module ReportsHelper
  def run_report
    click_on "Go"

    expect(page).to have_button "Go", disabled: true
    expect(page).to have_selector ".loading"

    perform_enqueued_jobs(only: ReportJob)

    expect(page).not_to have_selector ".loading"
    expect(page).to have_button "Go", disabled: false
  end
end
