# -*- ruby -*-

########################################
# Rules

rule(%r{data/icons/16x16/(.*).png} => ["%{16x16,svg}d/%{.png,.svg}f"]) do |t|
  mkdir_p File.dirname(t.name) unless File.directory?(File.dirname(t.name))
  sh "inkscape -e '#{t.name}' -w 16 '#{t.source}' > /dev/null"
end

rule(%r{data/icons/32x32/(.*).png} => ["%{32x32,svg}d/%{.png,.svg}f"]) do |t|
  mkdir_p File.dirname(t.name) unless File.directory?(File.dirname(t.name))
  sh "inkscape -e '#{t.name}' -w 32 '#{t.source}' > /dev/null"
end

rule(%r{data/icons/nativesize/(.*).png} => ["%{nativesize,svg}d/%{.png,.svg}f"]) do |t|
  mkdir_p File.dirname(t.name) unless File.directory?(File.dirname(t.name))
  sh "inkscape -e '#{t.name}' '#{t.source}' > /dev/null"
end

########################################
# Tasks

desc "Uses `inkscape' to convert all the SVGs to PNGs."
task :pngs => [:png16, :png32, :pngnative]

task :png16 => FileList["data/icons/svg/**/*.svg"].pathmap("%{svg,16x16}d/%{.svg,.png}f")
task :png32 => FileList["data/icons/svg/**/*.svg"].pathmap("%{svg,32x32}d/%{.svg,.png}f")
task :pngnative => FileList["data/icons/svg/**/*.svg"].pathmap("%{svg,nativesize}d/%{.svg,.png}f")
