# Configuration data file (shareconfigdata.psd1)
# Array of hashtables defining environmental data

@{g

    # Node specific data
    allNodes = @{
                NodeName           = "*"
            ShareName        = "Scripted_ShareTest"
            SourcePath         = "\\cfsbckcrmapp01\Global_shared\test"
            DestinationPath    = "C:\scripted_share\test"
            Description = "DSC created SMB Share"

       },

            @{
            NodeName           = "cfsnthitinfs02"
            Role               = "sharetarget"
            },
            @{
            NodeName           = "S2"
            Role               = "sharetarget"
            }
            @{
            NodeName           = "S3"
            Role               = "appserver"
            }

    }