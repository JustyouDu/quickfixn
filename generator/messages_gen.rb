

class MessageGen
  def self.generate messages, dir, fixver
    messages.each do |msg| 
      msgstr = gen_msg(msg, fixver)
      msg_path = File.join(dir, fixver, msg[:name] + '.cs')
      puts 'generate ' + msg_path
      File.open(msg_path, 'w') {|f| f.puts(msgstr) }
    end
  end

  def self.lower str
    str = str.clone
    str[0] = str[0].downcase
    str
  end

  def self.gen_msg msg, fixver 
<<HERE
using QuickFix.Fields;
namespace QuickFix
{
    namespace #{fixver} 
    {
        public class #{msg[:name]} : Message
        {
#{ctor(msg)}
#{ctor_req(msg)}
#{gen_msg_fields(msg[:fields], 12)}
#{gen_msg_groups(msg[:groups], 12)}
        }
    }
}
HERE
  end

  def self.ctor msg
<<HERE
            public #{msg[:name]}() : base()
            {
                this.Header.setField(new QuickFix.Fields.MsgType("#{msg[:msgtype]}"));
            }
HERE
  end

  def self.ctor_req msg
    req = required_fields(msg)
    req_args = req.map {|r| ' '*20 + "QuickFix.Fields.#{r[:name]} a#{r[:name]}" }
    req_setters = req.map {|r| ' '*16 + "this.#{lower(r[:name])} = a#{r[:name]};" }
<<HERE
            public #{msg[:name]}(
#{req_args.join(",\n")}
                ) : this()
            {
#{req_setters.join("\n")}
            }
HERE
  end

  def self.gen_msg_fields fields, prepend_spaces
    fields.map { |fld| msg_field(fld,prepend_spaces) }.join("\n")
  end

  def self.gen_msg_groups groups, prepend_spaces
    groups.map { |grp| msg_grp(grp, prepend_spaces) }.join("\n")
  end


  def self.required_fields msg
    msg[:fields].select {|f| f[:required] == true and f[:group] == false }
  end

  def self.msg_field fld, prepend_spaces
    str = []
    str << "public QuickFix.Fields.#{fld[:name]} #{lower(fld[:name])}"
    str << "{ "
    str << "    get "
    str << "    {"
    str << "        QuickFix.Fields.#{fld[:name]} val = new QuickFix.Fields.#{fld[:name]}();"
    str << "        getField(val);"
    str << "        return val;"
    str << "    }"
    str << "    set { setField(value); }"
    str << "}"
    str << ""
    str << "public void set(QuickFix.Fields.#{fld[:name]} val) "
    str << "{ "
    str << "    this.#{lower(fld[:name])} = val;"
    str << "}"
    str << ""
    str << "public QuickFix.Fields.#{fld[:name]} get(QuickFix.Fields.#{fld[:name]} val) "
    str << "{ "
    str << "    getField(val);"
    str << "    return val;"
    str << "}"
    str << ""
    str << "public bool isSet(QuickFix.Fields.#{fld[:name]} val) "
    str << "{ "
    str << "    return isSet#{fld[:name]}();"
    str << "}"
    str << ""
    str << "public bool isSet#{fld[:name]}() "
    str << "{ "
    str << "    return isSetField(Tags.#{fld[:name]});"
    str << "}"
    str.map! {|s| ' '*prepend_spaces + s}
    str.join("\n")
  end

  def self.msg_grp grp, prepend_spaces
    str = []
    str << "public class #{grp[:name]} : Group"
    str << "{"
    str << "    public #{grp[:name]}() "
    str << "      :base( Tags.#{grp[:group_field][:name]}, Tags.#{grp[:fields][0][:name]}, fieldOrder)"
    str << "    {"
    str << "    }"
    str << "    public static int[] fieldOrder = {#{grp_field_order grp[:fields] }};"
    str << gen_msg_fields(grp[:fields], prepend_spaces+4)
    str << gen_msg_groups(grp[:groups], prepend_spaces+4)
    str << "}"
    str.map {|s| ' '*prepend_spaces + s}.join("\n")
  end

  def self.grp_field_order fields
    field_order = fields.map {|f| "Tags.#{f[:name]}"}
    field_order << "0"  ## um, because qf and qfj do it
    field_order.join(", ")
  end
end
