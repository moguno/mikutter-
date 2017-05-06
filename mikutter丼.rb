require "mastodon"
require "oauth2"
require "sanitize"
require "thread"

require_relative "monkey_patches"
require_relative "datasource"
require_relative "models"
require_relative "settings"
require_relative "world_setting"

Plugin.create(:"mikutter丼") {
  @timelines = [
    [ :streaming_local_timeline, "ローカルタイムライン" ],
    [ :streaming_public_timeline, "連邦タイムライン" ],
    [ :streaming_user_timeline, "ユーザタイムライン" ],
  ]

  def message_factory_start(&xproc)
    queue = Queue.new

    Thread.new {
      loop {
        status = []

        10.times {
          status << queue.deq

          if queue.empty?
            break
          end
        }

        if status.length != 0
          xproc.(status)
        end

        sleep(1.0)
      }
    }

    return queue
  end

  def to_message(mastodon_status)
    avatar_url = if mastodon_status.attributes["account"]["avatar"] =~ /^\//
      UserConfig[:don_instance] + "/" + mastodon_status.attributes["account"]["avatar"]
    else
      mastodon_status.attributes["account"]["avatar"]
    end

    user = DonUser.new_ifnecessary(
      name: mastodon_status.attributes["account"]["username"],
      idname: mastodon_status.attributes["account"]["acct"],
      uri: mastodon_status.attributes["account"]["url"],
      profile_image_url: avatar_url
    )

    message = DonMessage.new_ifnecessary(
      uri: mastodon_status.attributes["url"],
      created: Time.parse(mastodon_status.attributes["created_at"]).localtime,
      description: Sanitize.clean(mastodon_status.attributes["content"]),
      user: user
    )

    return message
  end

  on_period { |service|
    if service == Service.primary
=begin
      Thread.new {
        begin
          if !@client
            @client = get_client(UserConfig[:don_instance], UserConfig[:don_user], UserConfig[:don_password])
          end

          @timelines.each { |method, name|
            Thread.new {
              tmp = message_factory_start { |status|
                messages = status.map { |_| to_message(_) }

                Plugin.call(:extract_receive_message, :"mikutter丼/#{name}", messages)
              }

              Thread.current[:queue] = tmp

              @client.send(method) { |event, data|
                if event == "update"
                  Thread.current[:queue].enq(data)
                end
              }
            }
          }
        rescue => e
          puts e
          puts e.backtrace
        end
      }
=end
    end
  }
}
