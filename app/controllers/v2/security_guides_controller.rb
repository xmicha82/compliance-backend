# frozen_string_literal: true

module V2
  class SecurityGuidesController < ApplicationController
    def index
      render_json security_guides
    end

    def security_guides
      SecurityGuide.all
    end

    private

    def serializer
      V2::SecurityGuideSerializer
    end
  end
end
