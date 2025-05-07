require 'js'
require 'wasm_drb'
require 'uri'

module Gibier2
  class Page
    def metadata
      @metadata
    end

    def to_html
      @html
    end

    def marshal_load(obj)
      @html = obj[0]
      @metadata = obj[1]
    end
  end

  class Pages
    attr_reader :page_num

    def initialize(pages, page_num=0)
      @pages = pages
      @page_num = page_num
    end

    def page(n)
      @page_num = n
      current
    end

    def current
      @pages[@page_num]
    end

    def next
      if @page_num < @pages.length - 1
        @page_num += 1
      end
      current
    end

    def prev
      if @page_num > 0
        @page_num -= 1
      end
      current
    end

    def marshal_dump
      [@pages, @page_num]
    end

    def marshal_load(obj)
      @pages = obj[0]
      @page_num = obj[1]
    end
  end
end

uri = URI.parse(JS.global[:window][:location].to_s)
scheme = uri.scheme == 'https' ? 'wss' : 'ws'
ws_uri = uri.port ? "#{scheme}://#{uri.host}:#{uri.port}" : "#{scheme}://#{uri.host}"

Factory = DRb::DRbObject.new_with_uri ws_uri
DRb.start_service("#{ws_uri}/callback")

class Pages
  def self.pages
    @pages ||= Factory.pages
  end
end
