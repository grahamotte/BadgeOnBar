require_relative "lib/require"

if ENV.fetch("PUBLISH_STOP_BEFORE_PREPARE", "false") == "true"
  Apps.prepare_for_review = false
  Apps.submit_for_review = false
elsif ENV.fetch("PUBLISH_STOP_BEFORE_SUBMISSION", "false") == "true"
  Apps.submit_for_review = false
end

Apps::ValidationPatch.call
Apps::BuildPatch.call
Apps::RevisionPatch.call
Apps::UploadPatch.call
Apps::SubmitPatch.call
