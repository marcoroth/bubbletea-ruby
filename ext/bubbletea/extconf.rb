# frozen_string_literal: true

require "mkmf"

extension_name = "bubbletea"

def detect_platform
  cpu = RbConfig::CONFIG["host_cpu"]
  os = RbConfig::CONFIG["host_os"]

  arch = case cpu
         when /aarch64|arm64/ then "arm64"
         when /x86_64|amd64/ then "amd64"
         when /arm/ then "arm"
         when /i[3-6]86/ then "386"
         else cpu
         end

  goos = case os
         when /darwin/ then "darwin"
         when /mswin|mingw/ then "windows"
         else "linux"
         end

  "#{goos}_#{arch}"
end

platform = detect_platform
go_lib_dir = File.expand_path("../../go/build/#{platform}", __dir__)

puts "Looking for Go library in: #{go_lib_dir}"

unless File.exist?(File.join(go_lib_dir, "libbubbletea.a"))
  abort <<~ERROR
    Could not find libbubbletea.a for platform #{platform}

    Please build the Go archive first:
      cd go && go build -buildmode=c-archive -o build/#{platform}/libbubbletea.a .

    Or run:
      bundle exec rake go:build
  ERROR
end

$LDFLAGS << " -L#{go_lib_dir}"
$INCFLAGS << " -I#{go_lib_dir}"

$LOCAL_LIBS << " #{go_lib_dir}/libbubbletea.a"

case RbConfig::CONFIG["host_os"]
when /darwin/
  $LDFLAGS << " -framework CoreFoundation -framework Security -framework SystemConfiguration"
  $LDFLAGS << " -lresolv"
when /linux/
  $LDFLAGS << " -lpthread -lm -ldl"
  $LDFLAGS << " -lresolv" if find_library("resolv", "res_query")
end

$srcs = [
  "extension.c",
  "program.c",
]

create_makefile("#{extension_name}/#{extension_name}")
