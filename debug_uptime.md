# Debug Notes

```ruby
cards = []
cards << LiveCard.new(100191,11,5.0,10,:CU)
cards << LiveCard.new(100317,11,6.0,10,:SU)
cards << LiveCard.new(300191,11,6.0,10,:HP)
cards << LiveCard.new(300465, 7,3.0,10,:CC)
cards << LiveCard.new(200247, 9,4.0,10,:CU)
cards << LiveCard.new(200413, 9,4.0,10,:AR)
cards << LiveCard.new(100499,11,5.0,10,:SYN)
cards << LiveCard.new(200377, 8,5.0,10,:SB)

notes = []
songlen = 130
nil.tap do
  base_time = (rand * 7.0)
  mult_time = (0.25 + rand * 0.25)
  note_rate = 0.9
  dupe_rate = 0.08
  half_rate = 0.60
  trip_rate = 0.01
  quad_rate = 0.05
  
  curr_time = base_time
  begin
    catch(:note) do
      if rand > note_rate then
        throw(:note)
      end
      
      note_amt = 1
      while rand < dupe_rate
        note_amt += 1
      end
      
      notes.concat([curr_time] * note_amt)
    end
    
    next_mult = mult_time
    catch(:rate) do
      next_rate = rand
      
      if next_rate < quad_rate then
        next_mult /= 4.0
        throw(:rate)
      end
      next_rate -= quad_rate
      
      if next_rate < trip_rate then
        next_mult /= 3.0
        throw(:rate)
      end
      next_rate -= trip_rate
      
      if next_rate < half_rate then
        next_mult /= 2.0
        throw(:rate)
      end
      next_rate -= half_rate
    end
    curr_time += next_mult
  end while curr_time < songlen
  
  notes.map { |t| t.round(7) }
end

puts "given #{notes.size} combo"

uptime = BloomJewel::SkillUptime.new(cards,notes)
uptime.draw(songlen)
```
