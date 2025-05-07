require 'drb/drb'
require 'drb/websocket'
require 'rouge'
require 'yaml'
require_relative 'parser'

CONTENT_TYPES = {
  '.png' => 'image/png',
  '.jpg' => 'image/jpeg',
  '.jpeg' => 'image/jpeg',
  '.css' => 'text/css',
  '.svg' => 'image/svg+xml',
  '.js' => 'text/javascript'
}

class Gibier
  def self.pages
    markdown = File.read('slide.md')
    metayml = YAML.load_file('meta.yml')
    metadata = metayml['slide'].each_with_object({}) do |page, obj|
      if page['audio']
        audio_metadata = YAML.load_file("#{page['audio']['name']}.yml")
        obj[page['id']] = {'audio' => audio_metadata}
      end
    end
    Gibier2::Parser.parse(markdown, metadata)
  end
end

hostname = ENV['GIBIER_HOSTNAME'] || 'localhost'

DRb::WebSocket::RackApp.config.use_rack = true
DRb.start_service("ws://#{hostname}:9161", Gibier)

app = DRb::WebSocket::RackApp.new(Proc.new {|env|
  case path = env['REQUEST_PATH']
  when '/'
    html = File.read('./index.html')
    [200, { 'content-type' => 'text/html' }, [html] ]
  when '/dist/app.wasm'
    js = File.read('./dist/app.wasm')
    [200, { 'content-type' => 'application/wasm' }, [js] ]
  when '/css/highlight.css'
    css = Rouge::Themes::Base16.mode(:dark).render(scope: '.highlight')
    [200, { 'content-type' => 'text/css' }, [css] ]
  else
    if File.exist?('public' + path)
      content = File.read('public' + path)
      ext = File.extname(path)
      ctype = CONTENT_TYPES[ext]
      [200, { 'content-type' => ctype }, [content]]
    else
      [404, {}, []]
    end
  end
})

Rackup::Server.start app:app, Port: 9161
