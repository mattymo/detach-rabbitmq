notice('MODULAR: detach-rabbitmq/deploy_hiera_override.pp')

$detach_rabbitmq_plugin = hiera('detach-rabbitmq')
#lint:ignore:80chars
$yaml_additional_config = pick($detach_rabbitmq_plugin["yaml_additional_config"], {})
#lint:endignore
$amqp_port = hiera('amqp_port', '5673')
$nodes_hash = hiera('nodes')
$settings_hash = parseyaml($yaml_additional_config)


case hiera('role', 'none') {
  /rabbitmq/: {
    $rabbit_enabled = true
  }
  /controller/: {
    $rabbit_enabled = false
  }
  default: {
    $rabbit_enabled = true
  }
}

$amqp_nodes = nodes_with_roles($nodes_hash, ['rabbitmq-standalone'],
                              'internal_address')
$amqp_hosts = inline_template("<%= @amqp_nodes.map {|x| x + ':' + @amqp_port}.j
oin ',' %>")


$calculated_content = inline_template('
amqp_hosts: <%= @amqp_hosts %>
rabbit:
  enabled: <%= @rabbit_enabled %>
')

###################
file {'/etc/hiera/override':
  ensure  => directory,
} ->
file { '/etc/hiera/override/plugins.yaml':
  ensure  => file,
  content => "${yaml_additional_config}\n${calculated_content}\n",
}

package { 'ruby-deep-merge':
  ensure  => 'installed',
}

file_line { 'hiera.yaml':
  path => '/etc/hiera.yaml',
  line => ':merge_behavior: deeper',
}
