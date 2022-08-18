import { NgModule } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { A11yModule } from '@angular/cdk/a11y';
import { UIRouterModule } from '@uirouter/angular';
import { SPOT_DOCS_ROUTES } from './spot.routes';
import { SpotCheckboxComponent } from './components/checkbox/checkbox.component';
import { SpotToggleComponent } from './components/toggle/toggle.component';
import { SpotFilterChipComponent } from './components/filter-chip/filter-chip.component';
import { SpotDropModalComponent } from './components/drop-modal/drop-modal.component';
import { SpotTooltipComponent } from './components/tooltip/tooltip.component';
import { SpotDocsComponent } from './spot-docs.component';
import { SpotInputFieldComponent } from 'core-app/spot/components/input-field/input-field.component';

@NgModule({
  imports: [
    // Routes for /spot-docs
    UIRouterModule.forChild({ states: SPOT_DOCS_ROUTES }),
    FormsModule,
    CommonModule,
    A11yModule,
  ],
  declarations: [
    SpotDocsComponent,

    SpotCheckboxComponent,
    SpotToggleComponent,
    SpotInputFieldComponent,
    SpotFilterChipComponent,
    SpotDropModalComponent,
    SpotTooltipComponent,
  ],
  exports: [
    SpotCheckboxComponent,
    SpotToggleComponent,
    SpotInputFieldComponent,
    SpotFilterChipComponent,
    SpotDropModalComponent,
    SpotTooltipComponent,
  ],
})
export class OpSpotModule { }
