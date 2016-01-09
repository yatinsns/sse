# Usage: redis-cli publish message hello

require 'sinatra'
require 'redis'

conns = []

get '/' do
  erb :index
end

get '/subscribe' do
  content_type 'text/event-stream'
  stream(:keep_open) do |out|
    puts "got it"
    conns << out
    out.callback { conns.delete(out) }
  end
end

Thread.new do
  redis = Redis.connect
  redis.psubscribe('message', 'message.*') do |on|
    on.pmessage do |match, channel, message|
      channel = channel.sub('message.', '')
      
      puts "publishing"
      conns.each do |out|
        out << "event: #{channel}\n\n"
        out << "data: #{message}\n\n"
      end
    end
  end
end


__END__

@@index

<h1>Let's test server side events</h1>
<article id="log"></article>

<script>
  var source = new EventSource('/subscribe');

  source.addEventListener('message', function(event) {
    log.innerText += '\n' + event.data;
  }, false);
</script>

