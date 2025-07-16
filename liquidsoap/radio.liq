#!/usr/bin/liquidsoap

# Enable logging
set("log.stdout", true)
set("log.level", 3)

# Add FFmpeg decoder settings
set("decoder.ffmpeg.metadata.export", true)
set("decoder.ffmpeg.buffer.length", 0.5)
set("decoder.ffmpeg.analyze_duration", 10000000)

# Add buffer and decoder settings
set("frame.audio.size", 2048)
set("decoder.buffer.size", 32768)
set("root.max_latency", 60.)

# Define playlists with fallback
default = playlist(
    "/app/music/default/",
    mode="random",
    reload=3600,
    reload_mode="rounds"
)

silentminute = single(
    "/app/music/SilentMinute.mp3"
)

# doctors_silence_minute = single(
#     "/app/music/doctors_silence_mitute.mp3"
# )

# Make playlists safe and log their states
default = mksafe(default)
default.on_track(fun(m) -> begin
    filename = string.extract(pattern='[^/]*$', m["filename"])
    log("Now playing default: #{filename}")
end)

silentminute = mksafe(silentminute)
silentminute.on_track(fun(m) -> begin
    filename = string.extract(pattern='[^/]*$', m["filename"])
    log("Now playing silentminute: #{filename}")
end)

# doctors_silence_minute = mksafe(doctors_silence_minute)
# doctors_silence_minute.on_track(fun(m) -> begin
#     filename = string.extract(pattern='[^/]*$', m["filename"])
#     log("Now playing doctors_silence_minute: #{filename}")
# end)

# Function to get a random ad file from /app/music/ads/
def get_random_ad() =
    # List files in the ads directory
    files = process.read.lines("ls /app/music/ads/")
    # Filter out empty results and ensure we have files
    if list.length(files) > 0 then
        # Select a random file
        random_file = list.nth(files, int_of_float(float_of_int(list.length(files)) * random.float()))
        # Return full path
        "/app/music/ads/#{random_file}"
    else
        # Return empty string if no files
        ""
    end
end

# Create a queue for missed ads using ref
ad_queue = ref([])  # Store URIs of ads to play

def create_ad_request() =
    # Отримуємо поточну чергу
    current_queue = !ad_queue
    log("Queue size: #{list.length(current_queue)}")
    if list.length(current_queue) > 0 then
        # Беремо першу рекламу з черги
        ad_uri = list.hd(current_queue)
        # Видаляємо її з черги
        ad_queue := list.tl(current_queue)
        log("Playing ad from queue: #{ad_uri}")
        # Створюємо запит
        request.create(ad_uri)
    else
        # Якщо черга порожня, повертаємо null
        null()
    end
end

# Створюємо джерело для реклами
ad_source = request.dynamic(create_ad_request)
ad_source = mksafe(ad_source)
ad_source.on_track(fun(m) -> begin
    filename = string.extract(pattern='[^/]*$', m["filename"])
    log("Now playing ad: #{filename}")
end)

# Створюємо радіо з рекламою
radio_with_ads = fallback(track_sensitive=true, [
    ad_source,  # Спочатку намагаємося відтворити рекламу
    default     # Якщо немає реклами, відтворюємо основний плейлист
])

# Number of ads per hour
ad_times = 6
ad_interval = 60 / ad_times  

# Variable to track the last minute an ad was queued
last_ad_minute = ref(-1)  # Initialize to -1 to allow the first ad

def log_time() =
    time = time.local()
    current_minute = time.min
    log("Current time check - Hour: #{time.hour}, Minute: #{current_minute}, Second: #{time.sec}")
    
    # Check if the current minute is a multiple of ad_interval and hasn't been processed yet
    if current_minute mod ad_interval == 0 and current_minute != !last_ad_minute then
        # Get a random ad file
        ad_uri = get_random_ad()
        if ad_uri != "" then
            log("Adding ad to queue at #{time.hour}:#{current_minute}: #{ad_uri}")
            ad_queue := list.append(!ad_queue, [ad_uri])
            # Update the last ad minute
            last_ad_minute := current_minute
        else
            log("No ad available to queue at #{time.hour}:#{current_minute}")
        end
    end
end

# Schedule logging and queue management every 10 seconds to catch minute boundaries
thread.run(every=10., {log_time()})

# Create radio with ads and silent minutes
radio_with_ads = switch(track_sensitive=true, [
    ({list.length(!ad_queue) > 0}, ad_source),
    ({true}, default)
])

# Add silent minutes with track_sensitive=false
radio = switch(track_sensitive=false, [
    ({9h00m00s-9h03m18s}, silentminute),
    # ({14h00m00s-14h03m18s}, doctors_silence_minute),
    ({true}, radio_with_ads)
])

# Add a fallback silence in case all sources fail
radio = fallback(track_sensitive=false, [radio, blank(duration=5.)])

# Get Icecast password from environment
icecast_password = getenv("ICECAST_SOURCE_PASSWORD")

# Stream output to Icecast
output.icecast(
    %mp3(bitrate=128),
    host="icecast",
    port=8000,
    password=icecast_password,
    mount="stream",
    name="Scheduled Radio",
    description="Radio with scheduled programming",
    fallible=false,
    radio)