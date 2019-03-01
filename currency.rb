class Currency < ApplicationRecord

    translates :name
    globalize_accessors locales: I18n.available_locales, attributes: [:name]
    accepts_nested_attributes_for :translations, allow_destroy: true

    has_many :currency_translations, dependent: :delete_all

    def resolve_currencies
        resolve_usd
        resolve_krw
        resolve_eur
        resolve_rub
    end

    def rub_from(value, currency_code)
        currency_code = currency_code.downcase
        currency = ::Currency.find_by(code: currency_code)
        unless currency.present?
            return value
        end

        if currency.updated_at.to_date < DateTime.now.to_date
            resolve_currencies
        end

        nominal = currency.nominal
        value_in_rub = currency.value_in_rub
        
        value = ((value_in_rub.to_f / nominal.to_f).round(2) * value.to_f).to_f.round(2)
        value
    end

    def rub_to(value, currency_code)
        currency_code = currency_code.downcase
        currency = ::Currency.find_by(code: currency_code)
        unless currency.present?
            return value
        end

        if currency.updated_at.to_date < DateTime.now.to_date
            resolve_currencies
        end

        nominal = currency.nominal
        value_in_rub = currency.value_in_rub

        value = (value.to_f / ((value_in_rub.to_f / nominal.to_f).round(2))).to_f.round(2)
        value
    end

    def name_by_locale(locale)
        return send("name_#{locale}")
    end

    private

    def pull_currencies
        url = URI.parse('http://www.cbr.ru/scripts/XML_daily.asp')
        request = Net::HTTP::Get.new(url.to_s)
        result = Net::HTTP.start(url.host, url.port) {|http|
          http.request(request)
        }
        result.body
    end
    
    def get_currency_value(currency_code)
        currency_code = currency_code.upcase

        nominal = 1
        value = 1
    
        all_currencies_xml = pull_currencies
    
        xml_doc = Nokogiri::XML(all_currencies_xml)
        xml_doc.search('ValCurs Valute').each do |valute|
          if valute.at('CharCode').text == currency_code
            nominal = valute.at('Nominal').text
            value = valute.at('Value').text
          end
        end
    
        return nominal, value
    end

    def resolve_usd
        usd = ::Currency.find_by(code: :usd)
        unless usd.present?
            attrs = {
                code: :usd
            }
            usd = ::Currency.new(attrs)
        end

        nominal, value_in_rub = get_currency_value("usd")
        usd.nominal = nominal
        usd.value_in_rub = value_in_rub
        usd.save
    end

    def resolve_krw
        krw = ::Currency.find_by(code: :krw)
        unless krw.present?
            attrs = {
                code: :krw
            }
            krw = ::Currency.new(attrs)
        end

        nominal, value_in_rub = get_currency_value("krw")
        krw.nominal = nominal
        krw.value_in_rub = value_in_rub
        krw.save
    end

    def resolve_eur
        eur = ::Currency.find_by(code: :eur)
        unless eur.present?
            attrs = {
                code: :eur
            }
            eur = ::Currency.new(attrs)
        end

        nominal, value_in_rub = get_currency_value("eur")
        eur.nominal = nominal
        eur.value_in_rub = value_in_rub
        eur.save
    end

    def resolve_rub
        rub = ::Currency.find_by(code: :rub)
        unless rub.present?
            attrs = {
                code: :rub,
                name_ru: "руб",
                name_en: "rub",
                name_ko: "루블"
            }
            rub = ::Currency.new(attrs)
        end

        rub.nominal = 1
        rub.value_in_rub = 1
        rub.save
    end
end
  