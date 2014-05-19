setcode { false }
if FileTest.directory?("/var/local/ceph1")
    Facter.add("ceph_osd_test") do
        setcode { true }
    end
end
