require 'json'

# Load non-public global module
require 'bjp/common'
# Load separated scanner
require_relative 'scanner'

module BloomJewel; end
LiveCard = Struct.new(:id,:interval,:base_uptime,:level,:skill,:name)
class LiveCard
  SKILL_TABLE = {
    SU: [1,2,3],
    CU: [4],
    PL: [5,6,7,8],
    CG: [9,10,11],
    DG: [12],
    LR: [13],
    OL: [14],
    CC: [15],
    MM: [16],
    HP: [17,18,19],
    SB: [20],
    FOC:[21,22,23],
    AR: [24],
    SL: [25],
    SYN:[26],
    CRD:[27],
    AC: [28,29,30],
    TUN:[31],
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
  def draw(length,songname)
    length = [[length.to_f,20.0].max,180.0].min
    cw,ch = 1366,560
    
    img = Magick::Image.new(cw,ch) do self.background_color = 'white' end
    canvas = Magick::Draw.new
    
    begin
      #
      canvas.stroke_width(1)
      canvas.stroke('black')
      canvas.fill('none')
      #
      ss = {}
      rx, ry = 96, 64
      rw, rh = cw - 32, 448
      spx = ->(time){ rx + Rational(time,length) * (rw - rx) }
      sprx = ->(time){ spx.call(time).round }
      rcx = ->(time,uptime){ [time,[time+uptime,length].min].map(&sprx) }
      #
      skc = {
        OL: [:SU,:CG],
        CC: [:SU],
        FOC:[:SU,:CU],
        AR: [:CU,:HP],
        SL: [:CU],
        SYN:[:SU,:CU,:HP],
        CRD:[:SU,:CU],
        AC: [:SU],
        TUN:[:CU,:PL],
      }
      #skn = {
      #  OL:
      #}
      canvas.stroke('none')
      canvas.fill('black')
      canvas.text_align(2)
      canvas.text(cw >> 1,ry - 8,"Uptime Chart for #{songname}")
      #
      {
        SU: '#FF8040',
        CU: '#EEFF60',
        HP: '#50FF80',
        
        PL: '#60FFCC',
        CG: '#778830',
        DG: '#30EEFF',
        LR: [:HP], # undecided placeholder
        MM: '#CC33FF',
        SB: '#FF3333',
        
        OL: [:SU,:CG],
        CC: '#7710BB',
        
        FOC:[:SU,:CU],
        AR: [:CU,:HP],
        SL: [:CU],
        SYN:[:SU,:CU,:HP],
        CRD:[:SU,:CU],
        
        AC: [:SU],
        TUN:[:CU,:PL],
      }.tap do |skills|
        cardi = 1
        cardn = @cards.size + 1
        # -- UPCARD / CARD UPTIME --
        getc = ->(skill){
          case skills[skill]
          when String
            [skills[skill]]
          when Array
            skills.select{|k| skills[skill].include?(k) }.values
          else
            ['gray']
          end
        }
        dskill = ->(co,ci,cn,x1,x2,ym,yl,yh){
          yc    = (yl + Rational(ci,cn) * yh).round
          ya,yb = yc - ym, yc + ym
          yn = co.size
          co.size.times do |yi|
            y1,y2 = [yi,yi+1].map{|yx|ya + Rational(yx,yn)*(yb-ya)}.map(&:round)
            color = co[yi]
            canvas.stroke('none')
            canvas.fill(color)
            canvas.rectangle(x1,y1,x2,y2)
          end
        }
        canvas.text_align(Magick::RightAlign)
        @cards.each do |card|
          colors    = getc.call(card.skill)
          rup_song  = 0.0
          rup_combo = 0
          card.interval.step(length,card.interval) do |utime|
            next if utime > @notes.max
            up_max     = [card.uptime,card.interval,length - utime].min
            rup_song  += Rational(up_max,length) * 100
            rup_combo += @notes.count { |t| t.between?(utime,utime + up_max) }
            skc.fetch(card.skill,[card.skill]).each do |skpure|
              ss[skpure] ||= []
              ss[skpure] << [utime,utime + card.uptime]
            end
            x1,x2 = rcx.call(utime,up_max)
            dskill.call(colors,cardi,cardn,x1,x2,12,ry,rh-ry)
          end
          rup_note  = Rational(rup_combo, @notes.size) * 100
          # draw text here
          y2 = (ry + Rational(cardi,cardn) * (rh-ry)).round
          canvas.stroke('none')
          canvas.fill('black')
          canvas.font_size(12)
          canvas.text(rx-2,y2-4,"%s (%s)"%[card.name,card.skill])
          canvas.font_size( 9)
          canvas.text(rx-2,y2+4,"%.1f%% notes\n%.1f%% song\n%d notes"%[rup_note,rup_song,rup_combo])
          cardi += 1
        end
        # -- UPSKILL / OVERALL SKILL UPTIME
        ss.each do |sk,sv|
          sv.uniq!
          sv.sort!
          #sv.sort_by! do |(sa,sb)| [sa,sb] end
          si,sj = 0,0
          while si < sv.size
            sj = si + 1
            break if sj >= sv.size
            s1,s2 = sv[si],sv[sj]
            m1,m2 = s1.max,s2.max
            mx = s1 + s2
            if mx != mx.sort || mx != mx.uniq then
               sv.delete_at(sj)
              s1.replace([mx.min,mx.max])
            else
              si += 1
            end
          end
        end
        canvas.stroke('none')
        cardi = 1
        cardn = ss.size
        cwh = ch-(rh+32)
        cws = Rational(cwh,2 * ss.size)
        ss.each do |skill,suptimes|
          colors = getc.call(skill)
          rup_song  = 0.0
          rup_combo = 0
          suptimes.each do |u1,u2|
            rup_song  += Rational([u2,length].min-u1,length) * 100
            rup_combo += @notes.count { |t| t.between?(u1,u2) }
            x1,x2 = rcx.call(u1,u2-u1)
            dskill.call(colors,cardi,cardn,x1,x2,cws,rh - cws,cwh)
          end
          rup_note = Rational(rup_combo, @notes.size) * 100
          # draw text here
          y2 = ((rh - cws) + Rational(cardi,cardn) * (cwh)).round
          canvas.stroke('none')
          canvas.fill('black')
          canvas.font_size(12)
          canvas.text(rx-2,y2+4,"%s"%[skill])
          canvas.font_size( 9)
          if ss.size >= 5 then
            canvas.text(rx-(2 + skill.to_s.size * 10),y2+4,"%.1f%%/%.1f%%/%d"%[rup_note,rup_song,rup_combo])
          else
            canvas.text(rx-(2 + skill.to_s.size * 10),y2+0,"%.1f%%/%.1f%%\n%d"%[rup_note,rup_song,rup_combo])
          end
          cardi += 1
        end
      end
      #
      canvas.stroke_width(1)
      canvas.fill('none')
      ['#00008030','#00800030','#80000030'].tap do |colors|
        timesets = @notes.uniq.map{|t|[t,@notes.count(t)]}.sort_by(&:first).to_h
        timesets.each do |time,count|
          canvas.stroke colors.at( [count,colors.size].min - 1 )
          tx = sprx.call(time)
          canvas.line(tx,ry,tx,rh)
        end
      end
      canvas.stroke('black')
      canvas.rectangle(rx,ry,rw,rh)
      canvas.rectangle(rx,rh,rw,ch-32)
      #
    rescue => e
      $stderr.puts "#{e.class}: #{e.message}"
      $stderr.puts e.backtrace.first(7)
    end
    
    canvas.draw(img)
    ctime = [Time.now.to_f].pack('G').unpack('h*').first
    ctime = '0000000000000000' if ENV.key?('DEBUG')
    cfn = 'results/%s.png'%[ctime]
    img.write(cfn)
    puts JSON.dump({'file':cfn})
    
    self
  end
end

begin
  $scin = Scanner.new($stdin)
  private
  def read_cards
    code = $scin.read(String)
    case code
    when 'm'
      id = $scin.read(Integer)
      id -= 1 if id.even?
      rt = nil
      BloomJewel.sqlite3(:master,:master) do |db|
        att = {}
        db.execute('select available_time_type,available_time_min from available_time_type').each do |(id,tmin)|
          att.store(id,Rational(tmin,100))
        end
        db.get_first_row('select id,condition,available_time_type,10,skill_type from skill_data where id = ?',[id]).tap do |skill|
          skill[2] = att[ skill[2] ]
          skill[3] = $scin.read(Integer)
          skill[5] = $scin.read(String)
          rt = LiveCard.new(*skill)
          rt&.skill!
        end
      end
      fail ValueError, "ID #{id} not found" if rt.nil?
      rt
    else
      LiveCard.new(*$scin.read(Integer,Integer,Float,Integer,Integer,String)).tap do |c| c.skill! end
    end
  end
  def read_notes
    $scin.read(Float)
  end
  def main
    argv  = ARGV.dup
    card  = $scin.read(Integer)
    cards = card.times.map do read_cards end
    mode  = $scin.read(String)
    case mode
    when 'f'
      cset, diff = $scin.read(Integer,Integer)
      chart = JSON.parse(File.read(BloomJewel.file(:radar,"s/%03d_%02d.json"%[cset,diff])))
      notes = chart.select{|t|[1,2,3].include?(t['type'])}.map{|t|t['sec']}
      slen  = chart.find{|t|t['type']==92}.fetch('sec')
    else
      combo = $scin.read(Integer)
      notes = combo.times.map do read_notes end
      slen  = $scin.read(Float)
    end
    sname = $scin.readline
    BloomJewel::SkillUptime.new(cards,notes).tap do |upt|
      upt.draw(slen,sname)
    end
  end
  main
end if $0 == __FILE__
