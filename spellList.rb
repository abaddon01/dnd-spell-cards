# NOTE(eriq): This is only for wizards... wiz biz only!
#Business Card Details
#Top left 60x60
#Bottom Right 640x980
#Total Size = 697 x 1039


require 'cgi'
require 'fileutils'
require 'json'
require 'shellwords'

PNG_OUT_DIR = File.join('out', 'png')


def spellFilename(name, ext)
  return name.downcase().gsub(' ', '_').gsub(/\W+/, '') + ".#{ext}"
end

def escape(text)
  return CGI::escapeHTML(text)
end


def character_known_spells( inPath )
  spells=[]
  File.open(inPath, 'r'){|inFile|
    inFile.each{|line|
      if ( line.match?('SPELLNAME') and line.match?('Known Spells') )
        nameS = line.rindex('SPELLNAME')+10;
        nameE = line.rindex('|TIMES')
        spell = line[nameS, nameE-nameS]
        levelS = line.rindex('SPELLLEVEL:')+11
        levelE = line.rindex('|SOURCE')
        level = line[levelS,levelE-levelS]
        classS = line.rindex('CLASS:')+6
        classE = line.rindex('|BOOK')
        casterclass= line[classS, classE-classS]
        puts "[#{nameS}] [#{spell} #{level}] [#{levelS} #{levelE}]"
        spells.push([spell,level, casterclass])
        
      end
    
    }
  }
  return spells
  
  
end

def main(inPath)
  spells = character_known_spells(inPath)
  copyDir = File.join( PNG_OUT_DIR, 'luna')
  FileUtils.mkdir_p(copyDir)
  spells.each{|spell|
    name = spellFilename(spell[0], 'png')
    level = spell[1]
    casterclass = spell[2]
    pngOutDir = File.join(PNG_OUT_DIR,casterclass, level)
    
    pngOutPath = File.join(pngOutDir, spellFilename(spell[0], 'png'))   
    if ( File.exists?(pngOutPath))
    copyPath = File.join(copyDir, spellFilename(level+' ' +spell[0], 'png'))
    puts "#{name} #{spell[1]} #{pngOutPath}"
    FileUtils.copy_entry(pngOutPath, copyPath)
    else
      puts "#{name} #{spell[1]} is missing"
    end
    
  }

end

def loadArgs(args)
  if (args.size() != 1 || args.map{|arg| arg.gsub('-', '').downcase()}.include?('help'))
    puts "USAGE: ruby #{$0} <input file>"
      
  end

  return args
end

if ($0 == __FILE__)
  main(*loadArgs(ARGV))
end
