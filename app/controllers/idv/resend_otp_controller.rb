module Idv
  class ResendOtpController < ApplicationController
    include IdvSession
    include PhoneOtpRateLimitable
    include PhoneOtpSendable

    # confirm_two_factor_authenticated before action is in PhoneOtpRateLimitable
    before_action :confirm_user_phone_confirmation_needed
    before_action :confirm_user_phone_confirmation_session_started

    def create
      result = send_phone_confirmation_otp
      analytics.track_event(Analytics::IDV_PHONE_CONFIRMATION_OTP_RESENT, result.to_h)
      if send_phone_confirmation_otp_rate_limited?
        handle_too_many_otp_sends
      else
        redirect_to idv_otp_verification_url
      end
    rescue Telephony::TelephonyError => telephony_error
      invalid_phone_number(telephony_error)
    end

    private

    def confirm_user_phone_confirmation_needed
      return unless idv_session.user_phone_confirmation
      redirect_to idv_review_url
    end

    def confirm_user_phone_confirmation_session_started
      return if idv_session.user_phone_confirmation_session.present?

      redirect_to idv_phone_url
    end
  end
end
