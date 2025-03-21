require 'drb/drb'
require 'drb/websocket'
require 'rouge'
require_relative 'parser'

CONTENT_TYPES = {
  'png' => 'image/png',
  'jpg' => 'image/jpeg',
  'jpeg' => 'image/jpeg',
  'css' => 'text/css'
}

class Gibier
  def self.pages
    markdown = File.read('slide.md')
    Gibier2::Parser.parse(markdown)
  end
end

DRb::WebSocket::RackApp.config.use_rack = true
DRb.start_service("ws://127.0.0.1:9161", Gibier.pages)

app = DRb::WebSocket::RackApp.new(Proc.new {|env|
  case path = env['REQUEST_PATH']
  when '/'
    html = File.read('./index.html')
    [200, { 'content-type' => 'text/html' }, [html] ]
  when '/dist/app.wasm'
    js = File.read('../dist/app.wasm')
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
