class Screen
  def self.clear!
    puts "\e[H\e[2J"
  end
  
  def self.check_clear!
    if APP_CONFIG["global"]['clear_screen_on_output']
      self.clear!
    end
  end
end