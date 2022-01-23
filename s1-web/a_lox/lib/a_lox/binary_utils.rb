module ALox
  module BinaryUtils
    extend self

    def pack_short(short)
      [short].pack("s>").bytes
    end

    def unpack_short(byte1, byte2)
      [byte1, byte2].map(&:chr).join.unpack1("s>")
    end
  end
end
