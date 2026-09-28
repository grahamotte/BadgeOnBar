SolidErrors.destroy_after = 30.days

if Rails.env.production?
  SolidErrors.username = ENV.fetch("DASHBOARD_USERNAME", "admin")
  SolidErrors.password = ENV.fetch("DASHBOARD_PASSWORD", "coolbeans")
end
