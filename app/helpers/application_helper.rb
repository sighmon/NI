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
            return "You haven't purchased anything yet."
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

    def user_expiry_as_string(user)
        return (user.subscription.try(:expiry_date).try(:strftime, "%e %B, %Y") or "No current subscription.")
    end
end
