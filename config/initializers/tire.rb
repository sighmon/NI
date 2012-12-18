Tire::Results::Collection.class_eval do
    def __find_records_by_ids(klass, ids)
        #@options[:load] === true ? klass.find(ids) : klass.find(ids, @options[:load])
        # FIXME: not quite sure what the second (nil? false?) argument to klass.find would be doing...
        klass.where(:id => ids)
    end
end
