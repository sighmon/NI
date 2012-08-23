module ApplicationHelper
    def issues_as_table(issues)
        if issues.try(:empty?)
            return "You haven't purchased any individual issues yet."
        else
            table = "<table class='table table-striped issues_as_table'><thead><tr><th>Title</th><th>Release date</th></tr></thead><tbody>"
            for issue in issues.sort_by {|x| x.release} do
                table += "<tr><td>#{link_to issue.title, issue_path(issue)}</td><td>#{issue.release.strftime("%B, %Y")}</td></tr>"
            end
            table += "</tbody></table>"
            return raw table
        end
    end

    def user_expiry_as_string(user)
        return (user.subscription.try(:expiry_date).try(:strftime, "%e %B, %Y") or "No current subscription.")
    end
end
