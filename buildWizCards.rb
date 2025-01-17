# NOTE(eriq): This is only for wizards... wiz biz only!
#Business Card Details
#Top left 60x60
#Bottom Right 640x980
#Total Size = 697 x 1039


require 'cgi'
require 'fileutils'
require 'json'
require 'shellwords'

require_relative 'data/cleanJSON'

HTML_DIR = File.join('html')
HTML_TEMPLATE_PATH = File.join(HTML_DIR, 'template.html')
HTML_BACK_TEMPLATE_PATH=File.join(HTML_DIR, 'back.html')
HTML_CARD_DIR = File.join(HTML_DIR, 'cards')
RELATIVE_SCHOOL_IMAGE_DIR = File.join('..', '..', 'images', 'school-symbols')
SCREENSHOT_PATH = 'screenshot.png'
PNG_OUT_DIR = File.join('out', 'png')
MKHTMLTOIMAGE_PATH='c:/Programs/wkhtmltopdf/bin/wkhtmltoimage.exe';

# Scaled up by 2
HTML_WIDTH = 697*2# 750 * 2
HTML_HEIGHT = 1039*2 #1050 * 2

SUB_PATTERN_LEVEL = '__LEVEL__'
SUB_PATTERN_NAME = '__NAME__'
SUB_PATTERN_SCHOOL = '__SCHOOL__'
SUB_PATTERN_CAST_TIME = '__CAST_TIME__'
SUB_PATTERN_RANGE = '__RANGE__'
SUB_PATTERN_DURATION = '__DURATION__'
SUB_PATTERN_PAGE = '__PAGE__'
SUB_PATTERN_DESCRIPTION = '__DESCRIPTION__'
SUB_PATTERN_SAVING_THROW = '__SAVING_THROW__'
SUB_PATTERN_SPELL_RESISTANCE='__SPELL_RESISTANCE__'

SUB_PATTERN_COMPONENT_VERBAL = '__COMPONENT_VERBAL__'
SUB_PATTERN_COMPONENT_SOMATIC = '__COMPONENT_SOMATIC__'
SUB_PATTERN_COMPONENT_MATERIAL = '__COMPONENT_MATERIAL__'
SUB_PATTERN_COMPONENT_FOCUS = '__COMPONENT_FOCUS__'
SUB_PATTERN_COMPONENT_XP = '__COMPONENT_XP__'

def spellFilename(name, ext)
  return name.downcase().gsub(' ', '_').gsub(/\W+/, '') + ".#{ext}"
end

def escape(text)
  text.gsub("“","'")
  text.gsub("”","'")
  text.gsub('—',' ')
  return CGI::escapeHTML(text)
end

def secretaryShortHand(text)
  return text.gsub(/[aeiou]/i, '')
end

def skipWords(text)
  words = text.split(/\s+/)
  return words.values_at(*(words.each_index().select{|i| i.even?})).join(' ')
end

def buildDescription(spell)
  return spell[KEY_DESCRIPTION].map{|text| "<p>#{escape(text)}</p>"}.join("\n")
  # return spell[KEY_DESCRIPTION].map{|text| "<p>#{escape(secretaryShortHand(text))}</p>"}.join("\n")
  # return spell[KEY_DESCRIPTION].map{|text| "<p>#{escape(skipWords(text))}</p>"}.join("\n")
end

def buildSavingThrow(spell)
  if ( spell[KEY_SAVING_THROW])
    return escape(spell[KEY_SAVING_THROW].strip)
  else
    return "None"
  end
end

def buildSpellResistance(spell)
  if ( spell[KEY_SPELL_RESISTANCE])
    return escape(spell[KEY_SPELL_RESISTANCE])
  else
    return "No"
  end
end


def buildCastingTime(spell)
  time = spell[KEY_CASTING_TIME][KEY_STRUCTURED][KEY_CASTING_TIME]
  time = escape(time)

  if (spell[KEY_CASTING_TIME][KEY_STRUCTURED][KEY_SEE_DESCRIPTION])
    time += '*'
  end

  return time
end

def buildRange(spell)
  range = spell[KEY_RANGE][KEY_STRUCTURED][KEY_RANGE]
  range = escape(range)

  if (spell[KEY_RANGE][KEY_STRUCTURED][KEY_SEE_DESCRIPTION])
    range += ' *'
  end

  return range
end

def buildDuration(spell)
  duration = spell[KEY_DURATION][KEY_STRUCTURED][KEY_DURATION]
  duration = escape(duration)

  suffix = ''
  if (spell[KEY_DURATION][KEY_STRUCTURED][KEY_DISMISSABLE])
    suffix += '[D]'
  end

  if (spell[KEY_DURATION][KEY_STRUCTURED][KEY_CONCENTRATION])
    suffix += '[C]'
  end

  if (spell[KEY_DURATION][KEY_STRUCTURED][KEY_SEE_DESCRIPTION])
    suffix += '*'
  end

  if (suffix != '')
    duration += ' ' + suffix
  end

  return duration
end


def writeSpellHTML(outPath, spell, level, template)
  File.open(outPath, 'w'){|outFile|
    File.open(template, 'r'){|inFile|
      inFile.each{|line|
        outFile.puts(line
          .gsub(SUB_PATTERN_LEVEL, escape(level))
          .gsub(SUB_PATTERN_NAME, escape(spell[KEY_NAME]))
          .gsub(SUB_PATTERN_SCHOOL, spell[KEY_SCHOOL].downcase())
          .gsub(SUB_PATTERN_CAST_TIME, buildCastingTime(spell))
          .gsub(SUB_PATTERN_RANGE, buildRange(spell))
          .gsub(SUB_PATTERN_DURATION, buildDuration(spell))
          .gsub(SUB_PATTERN_PAGE, escape(spell[KEY_PAGE]))
          .gsub(SUB_PATTERN_SAVING_THROW, buildSavingThrow(spell))
          .gsub(SUB_PATTERN_SPELL_RESISTANCE, buildSpellResistance(spell))
          .gsub(SUB_PATTERN_DESCRIPTION, buildDescription(spell))
          .gsub(SUB_PATTERN_COMPONENT_VERBAL, "#{spell[KEY_COMPONENTS][KEY_RAW].include?('V')}")
          .gsub(SUB_PATTERN_COMPONENT_SOMATIC, "#{spell[KEY_COMPONENTS][KEY_RAW].include?('S')}")
          .gsub(SUB_PATTERN_COMPONENT_MATERIAL, "#{spell[KEY_COMPONENTS][KEY_RAW].include?('M')}")
          .gsub(SUB_PATTERN_COMPONENT_FOCUS, "#{spell[KEY_COMPONENTS][KEY_RAW].include?('F')}")
          .gsub(SUB_PATTERN_COMPONENT_XP, "#{spell[KEY_COMPONENTS][KEY_RAW].include?('XP')}")
        )
      }
    }
  }
end

def htmlToPNG(inPath, outPath)
  args = [
    MKHTMLTOIMAGE_PATH,
    "--width","#{HTML_WIDTH}",
    "--height","#{HTML_HEIGHT}",
    '--disable-smart-width',
    # "--window-size=#{HTML_WIDTH},#{HTML_HEIGHT}",
    # '--screenshot',
    inPath,
    outPath
  ]
  puts "args [#{args}]"
  puts "Generating PNG: [#{inPath}] -> [#{outPath}]."
  # c:\Programs\wkhtmltopdf\bin\wkhtmltoimage.exe" --height 2100 --width 1500 --disable-smart-width
  #`{Shellwords.join(args)}`
  exeArgs = "#{Shellwords.join(args)}"
  puts exeArgs
  #Shell.undef_system_command(Shellwords.join(args))
  require 'open3'

  stdout,stderr,status = Open3.capture3("#{exeArgs}")
  puts stdout # => string containing standard output of your command
  puts stderr # => string containing standard ERROR of your command
  if status.success?
    puts "It worked!"
  else
    puts "OH NOES! Got exit code #{status.exitstatus}"
  end
  # FileUtils.mv(SCREENSHOT_PATH, outPath)
end

def main(inPath, spellList)
  spells = JSON.parse(File.read(inPath))

  # Partition the spells by level.
  spells.each{|spell|
    # Wiz-biz only.
    if (!spell[KEY_LEVEL][KEY_STRUCTURED].has_key?(spellList))
      next
    end

    level = spell[KEY_LEVEL][KEY_STRUCTURED][spellList].to_s()
    name = spell[KEY_NAME]

    htmlOutDir = File.join(HTML_CARD_DIR, level)
    FileUtils.mkdir_p(htmlOutDir)
      
    #      write front of card
    htmlOutPath = File.join(htmlOutDir, spellFilename(name, 'html'))

    writeSpellHTML(htmlOutPath, spell, level, HTML_TEMPLATE_PATH)

    pngOutDir = File.join(PNG_OUT_DIR, spellList, level)
    FileUtils.mkdir_p(pngOutDir)
    pngOutPath = File.join(pngOutDir, spellFilename(name, 'png'))
    htmlToPNG(htmlOutPath, pngOutPath)
    #   Write Back of card
    htmlOutPath = File.join(htmlOutDir, spellFilename(name+'_back', 'html'))

    writeSpellHTML(htmlOutPath, spell, level, HTML_BACK_TEMPLATE_PATH)

    pngOutDir = File.join(PNG_OUT_DIR, spellList, level)
    FileUtils.mkdir_p(pngOutDir)
    pngOutPath = File.join(pngOutDir, spellFilename(name+'_back', 'png'))
    htmlToPNG(htmlOutPath, pngOutPath)
    
  }
end

def loadArgs(args)
  if ( args.map{|arg| arg.gsub('-', '').downcase()}.include?('help'))
    puts "USAGE: ruby #{$0} <input file> [Wizard|Bard|Ranger|Cleric|Druid]"
    exit(1)
  end
  
  if (args.size() == 1 )
   vals= [args[0], 'Wizard']
  else
    vals = [args[0], args[1]]
  end  
    
  return vals
end

if ($0 == __FILE__)
  args = loadArgs(ARGV)
  main(args[0], args[1])
end
