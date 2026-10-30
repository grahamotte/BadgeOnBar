class MailDnsPatch < BasePatch
  class << self
    def needed?
      return true if Cloudflare.zone_id.blank?
      Cloudflare.missing_mail_dns_records.present?
    end

    def apply
      if Cloudflare.zone_id.blank?
        Cloudflare.create_zone
      end

      Cloudflare.missing_mail_dns_records.each do |record|
        Cloudflare.create_dns_record(record)
      end
    end
  end
end
