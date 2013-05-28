# -*- ruby -*-
require "rake/clean"

########################################
# Rules

rule(%r{data/icons/16x16/(.*).png} => ["%{16x16,svg}d/%{.png,.svg}f"]) do |t|
  mkdir_p File.dirname(t.name) unless File.directory?(File.dirname(t.name))
  sh "inkscape -e '#{t.name}' -w 16 '#{t.source}' > /dev/null"
end

rule(%r{data/icons/16x16/(.*).png} => ["%{16x16,realpng}p"]) do |t|
  mkdir_p File.dirname(t.name) unless File.directory?(File.dirname(t.name))
  sh "convert '#{t.source}' -size 16x16 '#{t.name}'"
end

rule(%r{data/icons/32x32/(.*).png} => ["%{32x32,svg}d/%{.png,.svg}f"]) do |t|
  mkdir_p File.dirname(t.name) unless File.directory?(File.dirname(t.name))
  sh "inkscape -e '#{t.name}' -w 32 '#{t.source}' > /dev/null"
end

rule(%r{data/icons/32x32/(.*).png} => ["%{32x32,realpng}p"]) do |t|
  mkdir_p File.dirname(t.name) unless File.directory?(File.dirname(t.name))
  sh "convert '#{t.source}' -size 32x32 '#{t.name}'"
end

rule(%r{data/icons/nativesize/(.*).png} => ["%{nativesize,svg}d/%{.png,.svg}f"]) do |t|
  mkdir_p File.dirname(t.name) unless File.directory?(File.dirname(t.name))
  sh "inkscape -e '#{t.name}' '#{t.source}' > /dev/null"
end

rule(%r{data/icons/nativesize/(.*).png} => ["%{nativesize,realpng}p"]) do |t|
  mkdir_p File.dirname(t.name) unless File.directory?(File.dirname(t.name))
  cp t.source, t.name
end

########################################
# Tasks

desc "Uses `inkscape' to convert all the SVGs to PNGs and copy the PNGs."
task :pngs => [:png16, :png32, :pngnative]

task :png16 => FileList["data/icons/svg/**/*.svg"].pathmap("%{svg,16x16}d/%{.svg,.png}f") + FileList["data/icons/realpng/**/*.png"].pathmap("%{realpng,16x16}p")
task :png32 => FileList["data/icons/svg/**/*.svg"].pathmap("%{svg,32x32}d/%{.svg,.png}f") + FileList["data/icons/realpng/**/*.png"].pathmap("%{realpng,32x32}p")
task :pngnative => FileList["data/icons/svg/**/*.svg"].pathmap("%{svg,nativesize}d/%{.svg,.png}f") + FileList["data/icons/realpng/**/*.png"].pathmap("%{realpng,nativesize}p")

########################################
# Other

CLOBBER.include("data/icons/16x16", "data/icons/32x32", "data/icons/nativesize")
