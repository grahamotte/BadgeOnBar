SolidErrors.destroy_after = 30.days

if Rails.env.production?
  SolidErrors.username = Settings.all.dig(:dashboard, :username) || "admin"
  SolidErrors.password = ENV.fetch("DASHBOARD_PASSWORD", "coolbeans")
end
