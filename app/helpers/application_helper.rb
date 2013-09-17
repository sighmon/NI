module ApplicationHelper
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
                table += "<tr><td>#{link_to purchase.issue.title, issue_path(purchase.issue)}</td>"
                table += "<td>#{purchase.issue.release.strftime("%B, %Y")}</td>"
                table += "<td>#{purchase.purchase_date.try(:strftime,"%d %B, %Y")}</td>"
                table += "<td>#{purchase.price_paid ? "$#{number_with_precision((purchase.price_paid / 100), :precision => 2)}" : "Free"}</td></tr>"
            end
            table += "</tbody></table>"
            return raw table
        end
    end

    def subscriptions_as_table(subscriptions)
        if subscriptions.try(:empty?)
            return "You don't have any subscriptions."
        else
            table = "<table class='table table-bordered purchases_as_table'><thead><tr><th>Purchase date</th><th>Valid from</th><th>Duration</th><th>Cancellation date</th><th>Autodebit?</th><th>Paper copy?</th><th>Price paid</th><th>Refund due</th><th>Refund paid?</th></tr></thead><tbody>"
            for subscription in subscriptions.sort_by {|x| x.purchase_date} do
                table += "<tr><td>#{subscription.purchase_date.try(:strftime,"%d %B, %Y")}</td>"
                table += "<td>#{subscription.valid_from.try(:strftime,"%d %B, %Y")}</td>"
                table += "<td>#{subscription.duration}</td>"
                table += "<td>#{subscription.cancellation_date.try(:strftime,"%d %B, %Y")}</td>"
                table += "<td>#{subscription.was_recurring? ? "#{subscription.paypal_profile_id}" : "No"}</td>"
                table += "<td>#{subscription.paper_copy? ? "Yes" : "No"}</td>"
                table += "<td>#{subscription.price_paid ? "$#{number_with_precision((subscription.price_paid / 100), :precision => 2)}" : "Free"}</td>"
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
            table = "<table class='table table-bordered purchases_as_table'><thead><tr><th>Username</th><th>Date created</th>#{if current_user.institution?; '<th>Edit</th>'; end;}</tr></thead><tbody>"
            for child in children.sort_by {|x| x.created_at}.reverse do
                table += "<td>#{link_to child.username, institution_user_path(child)}</td>"
                table += "<td>#{child.created_at.try(:strftime,"%d %B, %Y")}</td>"
                if current_user.institution
                    table += "<td>#{link_to "Edit", edit_institution_user_path(child), :class => 'btn btn-mini'} #{link_to "Delete", institution_user_path(child), :method => 'delete', :data => { :confirm => t('.confirm', :default => t("helpers.links.confirm", :default => 'Are you sure?')) }, :class => 'btn btn-mini btn-danger'}</td>"
                end
                table += "</tr>"
            end
            table += "</tbody></table>"
            return raw table
        end
    end

    def user_expiry_as_string(user)
        return (user.last_subscription.try(:expiry_date).try(:strftime, "%e %B, %Y") or "No current subscription.")
    end

    def cents_to_dollars(value)
        return number_with_precision((value / 100.0), :precision => 2)
    end

    def current_article_favourited?
        if not current_user.nil?
            return current_user.favourites.collect{|f| f.article_id}.include?(@article.id)
        else 
            return false
        end
    end

    def favourite_id_for_article(article)
        return article.favourites.find_by_user_id(current_user.id).id
    end

    def current_article_has_a_guest_pass?
        if not current_user.nil?
            return current_user.guest_passes.collect{|f| f.article_id}.include?(@article.id)
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
        link_to(name, '#', class: "add_fields", data: {id: id, fields: fields.gsub("\n", "")})
    end

end
