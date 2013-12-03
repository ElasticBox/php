if FileTest.directory?("/var/elasticbox/certificates")
    Facter.add("eb_certificates") do
        setcode { true }
    end
end