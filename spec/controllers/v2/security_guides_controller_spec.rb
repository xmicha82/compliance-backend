# frozen_string_literal: true

require 'rails_helper'

describe V2::SecurityGuidesController, type: :request do
  let(:ssg1) { FactoryBot.create(:benchmark) }
  let(:ssg2) { FactoryBot.create(:benchmark) }
  describe 'GET /api/compliance/v2/ssgs' do
    it 'responds with ok status' do
      get ssgs_url

      expect(response).to have_http_status :ok
    end

    it 'returns SSGs' do
      get ssgs_url

      binding.pry
    end
  end
end
