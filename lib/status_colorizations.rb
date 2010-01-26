class String
  def stat_color()
    return self.colorize(STATUS_COLORS[self])
  end
end