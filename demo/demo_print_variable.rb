#!/usr/bin/ruby

class Foo
    @@varStr = "a"
    @@varNum = 100

    def self.varStr
        @@varStr
    end

    def self.varNum
        @@varNum
    end
end

normalStr = "b"
normalNum = 200


# @_binding = binding
# def write_pair(p, b = @_binding)
#   eval("
#     local_variables.each do |v| 
#       if eval(v.to_s + \".object_id\") == " + p.object_id.to_s + "
#         puts v.to_s + ': ' + \"" + p.to_s + "\"
#       end
#     end
#   " , b)
# end



# write_pair(Foo.varStr)
# write_pair(Foo.varNum)

# write_pair(normalStr)
# write_pair(normalNum)

@_binding = binding
def eval_debug(expr, binding = @_binding)
   "#{expr} => #{eval(expr, binding)}"
end

eval_debug(normalStr)