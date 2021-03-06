//
//  TabApropos
//  CompteurGiletsJaunes
//
//  Created by Alexandre GUY on 23/12/2018.
//  Copyright © 2018 Alexandre GUY. All rights reserved.
//
//  Licence: GPLv3

//
//  La quatrième page
//

package org.giletsjaunes.compteur;

import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import org.giletsjaunes.compteur.ui.tabapropos.TabAproposFragment;


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// classe TabApropos
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
public class TabAPropos extends AppCompatActivity {


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // onCreate
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.tab_apropos_activity);
        if (savedInstanceState == null) {
            getSupportFragmentManager().beginTransaction()
                    .replace(R.id.container, TabAproposFragment.newInstance())
                    .commitNow();
        }
    }
}
