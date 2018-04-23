require_relative 'scannner'

module BloomJewel; end
LiveCard = Struct.new(:id,:interval,:base_uptime,:level,:skill)
class LiveCard
  SKILL_TABLE = {
    SU: [1,2,3],
    CU: [4,25],
    PL: [5,6,7,8],
    CG: [9,10,11],
    DG: [12],
    LR: [13],
    OL: [14],
    CC: [15],
    MM: [16],
    HP: [17,18,19],
    SB: [20],
    FC: [21,22,23],
    AR: [24],
    SYN:[26],
  }
  def skill!
    SKILL_TABLE.each do |skill, ids|
      next if !ids.include?(self.skill)
      self.skill = skill
    end
  end
  def uptime
    (base_uptime.to_f * (1 + 0.5 * Rational([level.to_i,1].max - 1,9)) ).to_f
  end
end
class BloomJewel::SkillUptime
  require 'rmagick'
  def initialize(cards,notes)
    @cards = cards.select{|c|c.is_a?(LiveCard)}
    @notes = notes.select{|c|c.is_a?(Numeric)}.map(&:to_f)
    
    @cards.each(&:skill!)
  end
  def draw(length)
    length = [[length.to_f,20.0].max,180.0].min
    cw,ch = 1366,480
    
    img = Magick::Image.new(cw,ch) do self.background_color = 'white' end
    canvas = Magick::Draw.new
    
    begin
      #
      canvas.stroke_width(1)
      canvas.stroke('black')
      canvas.fill('none')
      #
      rx, ry = 96, 64
      rw, rh = cw - 32, 448
      spx = ->(time){ rx + Rational(time,length) * (rw - rx) }
      sprx = ->(time){ spx.call(time).round }
      rcx = ->(time,uptime){ [time,[time+uptime,length].min].map(&sprx) }
      #
      {
        SU: '#FF8040',
        CU: '#EEFF60',
        HP: '#50FF80',
        
        PL: '#60FFCC',
        CG: '#778830',
        DG: '#30EEFF',
        LR: [:HP],
        MM: '#CC33FF',
        SB: '#FF3333',
        
        OL: [:SU,:CG],
        CC: '#7710BB',
        
        FC: [:SU,:CU],
        AR: [:CU,:HP],
        SYN:[:SU,:CU,:HP],
      }.tap do |skills|
        cardi = 1
        cardn = @cards.size + 1
        @cards.each do |card|
          colors = []
          case skills[card.skill]
          when String
            colors << skills[card.skill]
          when Array
            colors.concat skills.select{|k| skills[card.skill].include?(k) }.values
          else
            colors << 'gray'
          end
          card.interval.step(length,card.interval) do |utime|
            x1,x2 = rcx.call(utime,card.uptime)
            yc,ym = (ry + Rational(cardi,cardn) * (rh - ry)).round, 12
            ya,yb = yc - ym, yc + ym
            yn = colors.size
            colors.size.times do |yi|
              y1,y2 = [yi,yi+1].map{|yx|ya + Rational(yx,yn)*(yb-ya)}.map(&:round)
              color = colors[yi]
              canvas.stroke('none')
              canvas.fill(color)
              canvas.rectangle(x1,y1,x2,y2)
            end
          end
          cardi += 1
        end
      end
      #
      canvas.stroke_width(1)
      canvas.stroke('black')
      canvas.fill('none')
      canvas.rectangle(96,64,iw - 32,ih - 32)
      ['#00008030','#00800030','#80000030'].tap do |colors|
        timesets = @notes.uniq.map{|t|[t,@notes.count(t)]}.sort_by(&:first).to_h
        timesets.each do |time,count|
          canvas.stroke colors.at( [count,colors.size].min - 1 )
          tx = sprx.call(time)
          canvas.line(tx,64,tx,ih-32)
        end
      end
      #
    rescue => e
      $stderr.puts "#{e.class}: #{e.message}"
      $stderr.puts e.backtrace.first(7)
    end
    
    canvas.draw(img)
    ctime = [Time.now.to_f].pack('G').unpack('h*').first
    img.write('results/%s.png')
  end
end

begin
  
end if $0 == __FILE__

