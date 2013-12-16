include_recipe "monit"

node.default["monit"]["web_interface"] = {
  :enable  => false, # need it?
  :port    => 9527,
  :address => "localhost",
  :allow   => ["localhost", "ly:g0v"]
}


node.default["monit"]["default_monitrc_configs"] += ["lyapi.monitrc.erb"]

monit_monitrc "lyapi" do
end

