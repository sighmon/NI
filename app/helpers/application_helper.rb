module ApplicationHelper

    include Pagy::Frontend

    def issues_as_table(issues)
        if issues.try(:empty?)
            return "You haven't purchased any individual issues yet."
        else
            table = "<table class='table table-bordered issues_as_table'><thead><tr><th>Title</th><th>Release date</th></tr></thead><tbody>"
            for issue in issues.sort_by {|x| x.release} do
                table += "<tr><td>#{link_to issue.title, issue_path(issue)}</td><td>#{issue.release.strftime("%B, %Y")}</td></tr>"
            end
            table += "</tbody></table>"
            return raw table
        end
    end

    def purchases_as_table(purchases)
        if purchases.try(:empty?)
            return "You haven't purchased any individual magazines yet."
        else
            table = "<table class='table table-bordered purchases_as_table'><thead><tr><th>Title</th><th>Release date</th><th>Purchase date</th><th>Price</th></tr></thead><tbody>"
            for purchase in purchases.sort_by {|x| x.issue.release} do
                purchase_price = purchase.price_paid ? "$#{number_with_precision((purchase.price_paid / 100.0), :precision => 2)}" : "Free"
                table += "<tr><td>#{link_to purchase.issue.title, issue_path(purchase.issue)}</td>"
                table += "<td>#{purchase.issue.release.strftime("%B, %Y")}</td>"
                table += "<td>#{purchase.purchase_date.try(:strftime,"%d %B, %Y")}</td>"
                table += "<td>#{link_to purchase_price, issue_purchase_path(purchase.issue, purchase, format: 'mjml')}</td></tr>"
            end
            table += "</tbody></table>"
            return raw table
        end
    end

    def subscriptions_as_table(subscriptions)
        if subscriptions.try(:empty?)
            return "You don't have any subscriptions."
        else
            table = "<table class='table table-bordered purchases_as_table'><thead><tr><th>Purchase date</th><th>Valid from</th><th>Duration</th><th>Cancellation date</th><th>Autodebit?</th><th>Paper copy?</th><th>Paper only?</th><th>Price paid</th><th>Refund due</th><th>Refund paid?</th></tr></thead><tbody>"
            for subscription in subscriptions.sort_by {|x| x.purchase_date} do
                subscription_price = subscription.price_paid ? "$#{number_with_precision((subscription.price_paid / 100), :precision => 2)}" : "Free"
                table += "<tr><td>#{subscription.purchase_date.try(:strftime,"%d %B, %Y")}</td>"
                table += "<td>#{subscription.valid_from.try(:strftime,"%d %B, %Y")}</td>"
                table += "<td>#{subscription.duration}</td>"
                table += "<td>#{subscription.cancellation_date.try(:strftime,"%d %B, %Y")}</td>"
                table += "<td>#{subscription.was_recurring? ? "#{subscription.paypal_profile_id}" : "No"}</td>"
                table += "<td>#{subscription.paper_copy? ? "Yes" : "No"}</td>"
                table += "<td>#{subscription.paper_only? ? "Yes" : "No"}</td>"
                table += "<td>#{link_to subscription_price, subscription_path(subscription, format: 'mjml')}</td>"
                table += "<td>#{subscription.refund ? "$#{cents_to_dollars(subscription.refund)}" : ""}</td>"
                table += "<td>#{subscription.refunded_on ? "#{subscription.refunded_on.try(:strftime,"%d %B, %Y")} #{link_to('Undo?', admin_subscription_path(subscription), :method => :put, :class => 'btn btn-mini btn-success', :confirm => 'Are you sure you want to undo marking it refunded?')}" : "#{link_to('Refunded', admin_subscription_path(subscription), :method => :put, :class => 'btn btn-mini btn-danger', :confirm => 'Are you sure you want to mark this refund as paid?')}" }</td></tr>"
            end
            table += "</tbody></table>"
            return raw table
        end
    end

    def favourites_as_table(favourites)
        if favourites.try(:empty?)
            return "You don't have any favourite articles yet."
        else
            table = "<table class='table table-bordered purchases_as_table'><thead><tr><th>Title</th><th>Magazine</th><th>Date favourited</th></tr></thead><tbody>"
            for favourite in favourites.sort_by {|x| x.created_at}.reverse do
                table += "<tr><td>#{link_to favourite.article.title, issue_article_path(favourite.issue_id, favourite.article_id)}</td>"
                # table += "<td>#{favourite.article.publication.strftime("%B, %Y")}</td>"
                table += "<td>#{link_to favourite.article.issue.title, issue_path(favourite.issue_id)}</td>"
                table += "<td>#{favourite.created_at.try(:strftime,"%d %B, %Y")}</td>"
                if current_user.try(:admin?)
                    table += "<td>#{link_to 'Delete', issue_article_favourite_path(favourite.issue_id, favourite.article_id, favourite.id), :method => 'delete', :class => 'btn btn-mini btn-danger'}</td>"
                end
                table += "</tr>"
            end
            table += "</tbody></table>"
            return raw table
        end
    end

    def guest_passess_as_table(guest_passes, with_links)
        if guest_passes.try(:empty?)
            return "You haven't shared any articles yet."
        else
            table = "<table class='table table-bordered purchases_as_table'><thead><tr><th>Title</th>"
            if with_links
                table += "<th>Guest pass URL <br /><span style='font-weight:normal'>(right click + copy link)</span></th>"
            end
            table += "<th>Date shared</th></tr></thead><tbody>"
            for guest_pass in guest_passes.sort_by {|x| x.created_at}.reverse do
                table += "<tr><td>#{link_to guest_pass.article.title, issue_article_path(guest_pass.article.issue, guest_pass.article)}</td>"
                # table += "<td>#{guest_pass.article.publication.strftime("%B, %Y")}</td>"
                if with_links
                    table += "<td>#{generate_guest_pass_link_to(guest_pass)}</td>"
                end
                table += "<td>#{guest_pass.created_at.try(:strftime,"%d %B, %Y")}</td>"
                if current_user.try(:admin?)
                    table += "<td>#{link_to 'Delete', issue_article_guest_pass_path(guest_pass.article.issue, guest_pass.article, guest_pass), :method => 'delete', :class => 'btn btn-mini btn-danger'}</td>"
                end
                table += "</tr>"
            end
            table += "</tbody></table>"
            return raw table
        end
    end

    def children_as_table(children)
        if children.try(:empty?)
            return "You don't have any student accounts yet."
        else
            table = "<table class='table table-bordered purchases_as_table'><thead><tr><th>Username</th><th>Date created</th><th>Logins (last login)</th>#{if current_user.institution?; '<th>Edit</th>'; end;}</tr></thead><tbody>"
            for child in children.sort_by {|x| x.created_at}.reverse do
                table += "<td>#{link_to child.username, institution_user_path(child)}</td>"
                table += "<td>#{child.created_at.try(:strftime,"%d %B, %Y")}</td>"
                table += "<td>#{child.sign_in_count} <span class='author-note'>(#{child.current_sign_in_at.try(:strftime,"%d %b, %Y")} - #{child.current_sign_in_ip})</span></td>"
                if current_user.institution
                    table += "<td>#{link_to "Edit", edit_institution_user_path(child), :class => 'btn btn-mini'} #{link_to "Delete", institution_user_path(child), :method => 'delete', :data => { :confirm => t('.confirm', :default => t("helpers.links.confirm", :default => 'Are you sure?')) }, :class => 'btn btn-mini btn-danger'}</td>"
                end
                table += "</tr>"
            end
            table += "</tbody></table>"
            return raw table
        end
    end

    def articles_as_table(type)
        if type == "most_shared"
            guest_passes = GuestPass.order(:use_count).reverse.first(10)
            table = "<table class='table articles_as_table'><thead><tr>"
            table += "<th> </th>"
            table += "<th>Article</th>"
            table += "<th>Published</th>"
            table += "<th>Issue</th>"
            table += "<th>Views</th></tr></thead><tbody>"
            for guest_pass in guest_passes do
                first_image = guest_pass.article.first_image
                table += "<tr>"
                if first_image
                    table += "<td>#{link_to retina_image_tag(first_image.data_url(:thumb).to_s, :class => 'shadow-sm', :alt => ('NI' + guest_pass.article.issue.number.to_s + ' - ' + guest_pass.article.issue.title + ' - ' + guest_pass.article.issue.release.strftime("%B, %Y")), :title => ('NI' + guest_pass.article.issue.number.to_s + ' - ' + guest_pass.article.issue.title + ' - ' + guest_pass.article.issue.release.strftime("%B, %Y")), :size => "150x150"), generate_guest_pass_link_string(guest_pass)}</td>"
                else
                    table += "<td>#{link_to retina_image_tag("fallback/default_article_image.jpg", :width => "200", :class => "shadow"), generate_guest_pass_link_string(guest_pass)}</td>"
                end
                table += "<td><h4>#{link_to guest_pass.article.title, generate_guest_pass_link_string(guest_pass)}</h4><p>#{guest_pass.article.teaser}</p></td>"
                table += "<td>#{guest_pass.article.issue.release.strftime("%B, %Y")}</td>"
                table += "<td>#{link_to retina_image_tag(guest_pass.article.issue.cover_url(:thumb).to_s, :class => 'shadow-sm', :alt => ('NI' + guest_pass.article.issue.number.to_s + ' - ' + guest_pass.article.issue.title + ' - ' + guest_pass.article.issue.release.strftime("%B, %Y")), :title => ('NI' + guest_pass.article.issue.number.to_s + ' - ' + guest_pass.article.issue.title + ' - ' + guest_pass.article.issue.release.strftime("%B, %Y")), :size => "141x200"), issue_path(guest_pass.article.issue)}</td>"
                table += "<td>#{guest_pass.use_count}</td>"
                table += "</tr>"
            end
            table += "</tbody></table>"
            return raw table
        else
            # Other article type?
        end
    end

    def payment_notifications_as_table(notifications)
        if notifications.try(:empty?)
            return "You don't have any notifications."
        else
            table = "<table class='table table-bordered purchases_as_table'><thead><tr>"
            table += "<th>Status</th>"
            table += "<th>Transaction ID</th>"
            table += "<th>Transaction_type</th>"
            table += "<th>Date</th>"
            table += "</tr></thead><tbody>"
            for notification in notifications.sort_by {|x| x.created_at} do
                table += "<tr><td>#{notification.status}</td>"
                table += "<td>#{notification.transaction_id}</td>"
                table += "<td>#{notification.transaction_type}</td>"
                table += "<td>#{notification.created_at.try(:strftime,"%d %B, %Y")}</td></tr>"
            end
            table += "</tbody></table>"
            return raw table
        end
    end

    def user_expiry_as_string(user)
        return (user.try(:expiry_date).try(:strftime, "%e %B, %Y") or "No current subscription.")
    end

    def purchase_date_as_string(purchase_date)
        return (purchase_date.try(:strftime, "%e %B, %Y") or "Unknown date")
    end

    def cents_to_dollars(value)
        begin
            return number_with_precision((value / 100.0), :precision => 2)
        rescue
            return 0
        end
    end

    def cents_to_dollars_gst(value)
        begin
            return cents_to_dollars(value).to_f / 11.0
        rescue
            return 0
        end
    end

    def tax_invoice_number(purchase)
        begin
            if purchase.class.name == 'Purchase'
                return "#NI#{purchase.user.id}MAG#{purchase.id}"
            elsif purchase.class.name == 'Subscription'
                return "#NI#{purchase.user.id}SUB#{purchase.id}"
            else
                return "#NI#{purchase.user.id}UNKNOWN#{purchase.id}"
            end
        rescue
            return 'ERROR'
        end
    end

    def article_favourited?(article)
        if not current_user.nil? and not article.nil?
            return current_user.favourites.collect{|f| f.article_id}.include?(article.id)
        else 
            return false
        end
    end

    def favourite_id_for_article(article)
        return article.favourites.find_by_user_id(current_user.id).id
    end

    def article_has_a_guest_pass?(article)
        if not current_user.nil? and not article.nil?
            return current_user.guest_passes.collect{|f| f.article_id}.include?(article.id)
        else 
            return false
        end
    end
    
    def guest_pass_id_for_article(article)
        return article.guest_passes.find_by_user_id(current_user.id).id
    end

    def generate_guest_pass_link_to(guest_pass)
        return link_to "Guest pass link", issue_article_url(guest_pass.article.issue, guest_pass.article, :utm_source => "#{guest_pass.key}")
    end

    def generate_guest_pass_link_string(guest_pass)
        return issue_article_url(guest_pass.article.issue, guest_pass.article).to_s+"?utm_source=#{guest_pass.key}"
    end

    def link_to_add_fields(name, f, association)
        new_object = f.object.send(association).klass.new
        id = new_object.object_id
        fields = f.fields_for(association, new_object, child_index: id) do |builder|
          render(association.to_s.singularize + "_fields", f: builder)
        end
        link_to(name, '#', class: "add_fields btn btn-outline-secondary", data: {id: id, fields: fields.gsub("\n", "")})
    end

    # http://natashatherobot.com/devise-rails-sign-in/
    def resource_name
        :user
    end

    def resource
        @resource ||= User.new
    end

    def devise_mapping
        @devise_mapping ||= Devise.mappings[:user]
    end

    # Create a newint:// app link from the path handed in
    def app_link(from_link)
        "newint:/#{URI.parse(from_link).path}"
    end

    def sortable(column, title = nil)
      title ||= column.titleize
      css_class = column == sort_column ? "current #{sort_direction}" : nil
      direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
      link_to title, {:sort => column, :direction => direction}, {:class => css_class}
    end

    def start_delayed_jobs
        ApplicationHelper.start_delayed_jobs
    end

    def self.start_delayed_jobs
        if Rails.env.production?
            PlatformAPI
                .connect_oauth(ENV.fetch("HEROKU_OAUTH"))
                .dyno
                .create(
                    ENV.fetch("HEROKU_OAUTH_APP_NAME"),
                    command: "bundle exec bin/delayed_job run --exit-on-complete"
                )
        else
            Delayed::Worker.exit_on_complete = true
            Delayed::Worker.new.start
        end
    end

    # RPush push notifications

    def self.rpush_register_ios_app
        # Set-up iOS push notifications
        if Rails.env.production?
            app = Rpush::Apnsp8::App.find_or_create_by(name: ENV.fetch("RPUSH_APPLE_PRODUCTION_APP_NAME"))
            app.apn_key = ENV.fetch("APPLE_PRODUCTION_APN_KEY")
            app.environment = "production" # APNs environment.
            app.apn_key_id = ENV.fetch("APPLE_PRODUCTION_APN_KEY_ID")
            app.team_id = ENV.fetch("INAPP_TEAM_ID")
            app.bundle_id = ENV.fetch("ITUNES_BUNDLE_ID")
        else
            app = Rpush::Apnsp8::App.find_or_create_by(name: ENV.fetch("RPUSH_APPLE_DEVELOPMENT_APP_NAME"))
            app.apn_key = ENV.fetch("APPLE_DEVELOPMENT_APN_KEY")
            app.environment = "sandbox" # APNs environment.
            app.apn_key_id = ENV.fetch("APPLE_DEVELOPMENT_APN_KEY_ID")
            app.team_id = ENV.fetch("INAPP_TEAM_ID")
            app.bundle_id = ENV.fetch("ITUNES_BUNDLE_ID")
        end
        app.connections = 1
        app.save!
    end

    def self.rpush_create_ios_push_notification(token, data)
        # Create an iOS push notification (doesn't send, just creates) one at a time
        n = Rpush::Apnsp8::Notification.new
        if Rails.env.production?
            n.app = Rpush::Apnsp8::App.find_by_name(ENV.fetch("RPUSH_APPLE_PRODUCTION_APP_NAME"))
        else
            n.app = Rpush::Apnsp8::App.find_by_name(ENV.fetch("RPUSH_APPLE_DEVELOPMENT_APP_NAME"))
        end
        data[:sound] = "new-issue.caf"
        n.sound = data[:sound]
        n.deliver_after = data[:deliver_after]
        n.uri = generate_notification_uri(data)
        n.device_token = token # 64-character hex string
        n.alert = data[:body]
        # n.content_available = true
        n.data = data || {}
        n.save!
    end

    def self.rpush_register_android_app
        # Set-up Android push notifications
        # TODO: Update this to Firebase
        app = Rpush::Gcm::App.new
        if Rails.env.production?
            app = Rpush::Gcm::App.find_or_create_by(name: ENV.fetch("RPUSH_ANDROID_PRODUCTION_APP_NAME"))
            app.environment = "production" # APNs environment.
            app.auth_key = ENV.fetch("ANDROID_PRODUCTION_AUTH_KEY")
        else
            app = Rpush::Gcm::App.find_or_create_by(name: ENV.fetch("RPUSH_ANDROID_DEVELOPMENT_APP_NAME"))
            app.environment = "sandbox" # APNs environment.
            app.auth_key = ENV.fetch("ANDROID_DEVELOPMENT_AUTH_KEY")
        end
        app.connections = 1
        app.save!
    end

    def self.rpush_create_android_push_notification(tokens, data)
        # Create Android push notifications (takes an array of android device tokens)

        n = Rpush::Gcm::Notification.new
        if Rails.env.production?
            n.app = Rpush::Gcm::App.find_by_name(ENV.fetch("RPUSH_ANDROID_PRODUCTION_APP_NAME"))
        else
            n.app = Rpush::Gcm::App.find_by_name(ENV.fetch("RPUSH_ANDROID_DEVELOPMENT_APP_NAME"))
        end
        # To get the NI icon, data = {icon: 'ni_notification'}
        data[:icon] = 'ni_notification'
        data[:sound] = 'content://settings/system/notification_sound'
        # data[:vibrate] = 'Notification.DEFAULT_VIBRATE'
        n.deliver_after = data[:deliver_after]
        n.uri = generate_notification_uri(data)
        n.sound = data[:sound]
        n.registration_ids = tokens # Array of token strings
        n.notification = { body: data[:body],
                           icon: data[:icon],
                           sound: data[:sound],
                           vibrate: true
                         }
        n.data = data # { message: "hi mom!" }
        n.priority = 'high'        # Optional, can be either 'normal' or 'high'
        n.content_available = true # Optional
        # Optional notification payload. See the reference below for more keys you can use!
        # n.notification = { body: 'great match!',
        #                    title: 'Portugal vs. Denmark',
        #                    icon: 'myicon'
        #                  }
        n.save!
    end

    def self.generate_notification_uri(data)
        
        base_uri = "newint://"
        if data[:articleID] and data[:issueID]
            return base_uri + "issues/" + data[:issueID] + "/articles/" + data[:articleID]
        elsif data[:railsID]
            return base_uri + "issues/" + data[:railsID]
        else
            return base_uri
        end
    end

    def self.bad_ip_alert_text
        "Bad IP address in student account! Check your last entry, then go to Admin > Settings to remove this warning."
    end

    def self.no_tracking(request)
        exempt_pages = (request.try(:url).try(:include?, "securedrop") or request.try(:url).try(:include?, "how-to-leak"))
        return exempt_pages
    end

    def no_tracking(request)
        ApplicationHelper.no_tracking(request)
    end

    def log_event(category, action, label)
        # Log a google analytics event to limit ad spending
        session[:events] ||= Array.new
        session[:events] << {:category => category, :action => action, :label => label}
    end

    def log_fb_event(action, amount)
        # Log an event with Facebook to limit ad spending
        session[:fb_events] ||= Array.new
        session[:fb_events] << {:action => action, :amount => amount}
    end

    def self.redesigned?(object_date)
        object_date > Time.new(2018, 8).to_datetime
    end

    def self.has_been_updated(param, field)
        if field.nil? and not param.blank?
            return true
        elsif field.blank? and not param.blank?
            return true
        elsif field and not (field == param)
            return true
        else
            return false
        end
    end

end
