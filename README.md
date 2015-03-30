# GamiCent
GamiCent make your iOS application easy integrating with GameCenter.

1. Initilization

		let gamiCent = GemiCent.sharedInstance {
            (isAuthentified) -> Void in

            if isAuthentified {
                /* Success! */

            } else {
                /* Failed. */
                /* No internet connection? not authentified? */
            }
        }
        /* Set delegate */
        GemiCent.delegate = self
        