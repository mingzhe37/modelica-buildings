within Buildings.Fluid.HeatExchangers.CoolingTowers;
model Merkel "Cooling tower model based on Merkel's theory"
  extends Buildings.Fluid.HeatExchangers.CoolingTowers.BaseClasses.CoolingTower(
    final QWat_flow(y=-eps*QMax_flow));

  import cha =
    Buildings.Fluid.HeatExchangers.CoolingTowers.BaseClasses.Characteristics;

  final parameter Modelica.SIunits.MassFlowRate mAir_flow_nominal=
    m_flow_nominal/ratWatAir_nominal
    "Nominal mass flow rate of air"
    annotation (Dialog(group="Fan"));

  parameter Real ratWatAir_nominal(min=0, unit="1") = 1.2
    "Water-to-air mass flow rate ratio at design condition"
    annotation (Dialog(group="Nominal condition"));

  parameter Modelica.SIunits.Temperature TAirInWB_nominal
    "Nominal outdoor (air inlet) wetbulb temperature"
    annotation (Dialog(group="Heat transfer"));
  parameter Modelica.SIunits.Temperature TWatIn_nominal
    "Nominal water inlet temperature"
    annotation (Dialog(group="Heat transfer"));
  parameter Modelica.SIunits.Temperature TWatOut_nominal
    "Nominal water outlet temperature"
    annotation (Dialog(group="Heat transfer"));

  parameter Real fraFreCon(min=0, max=1, final unit="1") = 0.125
    "Fraction of tower capacity in free convection regime"
    annotation (Dialog(group="Heat transfer"));

  replaceable parameter Buildings.Fluid.HeatExchangers.CoolingTowers.Data.UAMerkel UACor
    constrainedby Buildings.Fluid.HeatExchangers.CoolingTowers.Data.UAMerkel
    "Coefficients for UA correction"
    annotation (
      Dialog(group="Heat transfer"),
      choicesAllMatching=true,
      Placement(transformation(extent={{20,60},{40,80}})));

  parameter Real fraPFan_nominal(unit="W/(kg/s)") = 275/0.15
    "Fan power divided by water mass flow rate at design condition"
    annotation (Dialog(group="Fan"));
  parameter Modelica.SIunits.Power PFan_nominal = fraPFan_nominal*m_flow_nominal
    "Fan power"
    annotation (Dialog(group="Fan"));

  parameter Real yMin(min=0.01, max=1, final unit="1") = 0.3
    "Minimum control signal until fan is switched off (used for smoothing
    between forced and free convection regime)"
    annotation (Dialog(group="Fan"));

  replaceable parameter cha.fan fanRelPow(
       r_V = {0, 0.1,   0.3,   0.6,   1},
       r_P = {0, 0.1^3, 0.3^3, 0.6^3, 1})
    constrainedby cha.fan
    "Fan relative power consumption as a function of control signal, fanRelPow=P(y)/P(y=1)"
    annotation (
    choicesAllMatching=true,
    Placement(transformation(extent={{60,60},{80,80}})),
    Dialog(group="Fan"));

  final parameter Modelica.SIunits.HeatFlowRate Q_flow_nominal(max=0)=
    -m_flow_nominal*cpWat_nominal*(TWatIn_nominal-TWatOut_nominal)
    "Nominal heat transfer, (negative)";
  final parameter Modelica.SIunits.ThermalConductance UA_nominal=
    NTU_nominal*CMin_flow_nominal
    "Thermal conductance at nominal flow, used to compute heat capacity";
  final parameter Real eps_nominal=
    Q_flow_nominal/((TAirInWB_nominal - TWatIn_nominal) * CMin_flow_nominal)
    "Nominal heat transfer effectiveness";
  final parameter Real NTU_nominal(min=0)=
      Buildings.Fluid.HeatExchangers.BaseClasses.ntu_epsilonZ(
      eps=min(1, max(0, eps_nominal)),
      Z=Z_nominal,
      flowRegime=Integer(Buildings.Fluid.Types.HeatExchangerConfiguration.CounterFlow))
    "Nominal number of transfer units";

  Modelica.Blocks.Interfaces.RealInput TAir(
    final min=0,
    final unit="K",
    displayUnit="degC")
    "Entering air wet bulb temperature"
    annotation (Placement(transformation(extent={{-140,20},{-100,60}})));

  Modelica.Blocks.Interfaces.RealInput y(unit="1") "Fan control signal"
    annotation (Placement(transformation(extent={{-140,60},{-100,100}})));

  Modelica.Blocks.Interfaces.RealOutput PFan(
    final quantity="Power",
    final unit="W")
    "Electric power consumed by fan"
    annotation (Placement(transformation(extent={{100,70},{120,90}}),
        iconTransformation(extent={{100,70},{120,90}})));

  Modelica.SIunits.MassFraction FRWat
    "Ratio actual over design water mass flow ratio";
  Modelica.SIunits.MassFraction FRAir
    "Ratio actual over design air mass flow ratio";

  Real eps(min=0, max=1, unit="1") "Heat exchanger effectiveness";

  Modelica.SIunits.SpecificHeatCapacity cpWat "Heat capacity of water";

  Modelica.SIunits.MassFlowRate mAir_flow "Air mass flow rate";

  Modelica.SIunits.Temperature TWatIn "Inlet temperature water";
  Modelica.SIunits.Temperature TAirOut "Outlet temperature air";
  Modelica.SIunits.Temperature TWatOut "Outlet temperature water";
  Modelica.SIunits.TemperatureDifference TApp(displayUnit="K")
    "Approach temperature difference";

  Modelica.SIunits.ThermalConductance CAir_flow
    "Heat capacity flow rate of air";
  Modelica.SIunits.ThermalConductance CWat_flow
    "Heat capacity flow rate of water";
  Modelica.SIunits.ThermalConductance CMin_flow(min=0)
    "Minimum heat capacity flow rate";

  Modelica.SIunits.HeatFlowRate QMax_flow
    "Maximum heat flow rate into air";

  Modelica.SIunits.ThermalConductance UAe(min=0)
    "Thermal conductance for equivalent fluid";
  Modelica.SIunits.ThermalConductance UA "Thermal conductance";


protected
  final package Air = Buildings.Media.Air "Package of medium air";

  final parameter Real fanRelPowDer[size(fanRelPow.r_V,1)]=
    Buildings.Utilities.Math.Functions.splineDerivatives(
      x=fanRelPow.r_V,
      y=fanRelPow.r_P,
      ensureMonotonicity=Buildings.Utilities.Math.Functions.isMonotonic(
        x=fanRelPow.r_P,
        strict=false))
    "Coefficients for fan relative power consumption as a function
    of control signal";

  final parameter Air.ThermodynamicState staAir_default=Air.setState_pTX(
      T=TAirInWB_nominal,
      p=Air.p_default,
      X=Air.X_default[1:Air.nXi]) "Default state for air";
  final parameter Medium.ThermodynamicState
    staWat_default=Medium.setState_pTX(
      T=TWatIn_nominal,
      p=Medium.p_default,
      X=Medium.X_default[1:Medium.nXi]) "Default state for water";

  parameter Real delta=1E-3 "Parameter used for smoothing";

  parameter Modelica.SIunits.SpecificHeatCapacity cpe_nominal=
    Buildings.Fluid.HeatExchangers.CoolingTowers.BaseClasses.Functions.equivalentHeatCapacity(
      TIn = TAirInWB_nominal,
      TOut = TAirOutWB_nominal)
    "Specific heat capacity of the equivalent medium on medium 1 side";
  parameter Modelica.SIunits.SpecificHeatCapacity cpAir_nominal=
    Air.specificHeatCapacityCp(staAir_default)
    "Specific heat capacity of air at nominal condition";
  parameter Modelica.SIunits.SpecificHeatCapacity cpWat_nominal=
    Medium.specificHeatCapacityCp(staWat_default)
    "Specific heat capacity of water at nominal condition";

  parameter Modelica.SIunits.ThermalConductance CAir_flow_nominal=
    mAir_flow_nominal*cpe_nominal
    "Nominal capacity flow rate of air";
  parameter Modelica.SIunits.ThermalConductance CWat_flow_nominal=
    m_flow_nominal*cpWat_nominal
    "Nominal capacity flow rate of water";
  parameter Modelica.SIunits.ThermalConductance CMin_flow_nominal=
    min(CAir_flow_nominal, CWat_flow_nominal)
    "Minimal capacity flow rate at nominal condition";
  parameter Modelica.SIunits.ThermalConductance CMax_flow_nominal=
    max(CAir_flow_nominal, CWat_flow_nominal)
    "Maximum capacity flow rate at nominal condition";
  parameter Real Z_nominal(
    min=0,
    max=1) = CMin_flow_nominal/CMax_flow_nominal
    "Ratio of capacity flow rate at nominal condition";

  parameter  Modelica.SIunits.Temperature TAirOutWB_nominal(fixed=false)
    "Nominal leaving air wetbulb temperature";

  Real UA_FAir "UA correction factor as function of air flow ratio";
  Real UA_FWat "UA correction factor as function of water flow ratio";
  Real UA_DifWB
    "UA correction factor as function of differential wetbulb temperature";
  Real corFac_FAir "Smooth factor as function of air flow ratio";
  Real corFac_FWat "Smooth factor as function of water flow ratio";
  Modelica.SIunits.SpecificHeatCapacity cpEqu
    "Specific heat capacity of the equivalent fluid";

initial equation
  // Heat transferred from air to water at nominal condition
  Q_flow_nominal = mAir_flow_nominal*cpe_nominal*(TAirInWB_nominal - TAirOutWB_nominal);

  assert(eps_nominal > 0 and eps_nominal < 1,
    "eps_nominal out of bounds, eps_nominal = " + String(eps_nominal) +
    "\n  To achieve the required heat transfer rate at epsilon=0.8, set |TAirInWB_nominal-TWatIn_nominal| = "
     + String(abs(Q_flow_nominal/0.8*CMin_flow_nominal)) +
    "\n  or increase flow rates. The current parameters result in " +
    "\n  CMin_flow_nominal = " + String(CMin_flow_nominal) +
    "\n  CMax_flow_nominal = " + String(CMax_flow_nominal));

  // Check validity of relative fan power consumption at y=yMin and y=1
  assert(cha.normalizedPower(per=fanRelPow, r_V=yMin, d=fanRelPowDer) > -1E-4,
    "The fan relative power consumption must be non-negative for y=0."
  + "\n   Obtained fanRelPow(0) = "
  + String(cha.normalizedPower(per=fanRelPow, r_V=yMin, d=fanRelPowDer))
  + "\n   You need to choose different values for the parameter fanRelPow.");
  assert(abs(1-cha.normalizedPower(per=fanRelPow, r_V=1, d=fanRelPowDer))<1E-4,
  "The fan relative power consumption must be one for y=1."
  + "\n   Obtained fanRelPow(1) = "
  + String(cha.normalizedPower(per=fanRelPow, r_V=1, d=fanRelPowDer))
  + "\n   You need to choose different values for the parameter fanRelPow."
  + "\n   To increase the fan power, change fraPFan_nominal or PFan_nominal.");

equation
  // Handling of flow reversal
   if allowFlowReversal then
    if homotopyInitialization then
      TWatIn=Medium.temperature(Medium.setState_phX(p=port_a.p,
          h=homotopy(actual=actualStream(port_a.h_outflow),
            simplified=inStream(port_a.h_outflow)),
          X=homotopy(actual=actualStream(port_a.Xi_outflow),
            simplified=inStream(port_a.Xi_outflow))));
      TWatOut=Medium.temperature(Medium.setState_phX(p=port_b.p,
          h=homotopy(actual=actualStream(port_b.h_outflow),
            simplified=port_b.h_outflow),
          X=homotopy(actual=actualStream(port_b.Xi_outflow),
            simplified=port_b.Xi_outflow)));
    else
      TWatIn=Medium.temperature(Medium.setState_phX(p=port_a.p,
          h=actualStream(port_a.h_outflow),
          X=actualStream(port_a.Xi_outflow)));
      TWatOut=Medium.temperature(Medium.setState_phX(p=port_b.p,
          h=actualStream(port_b.h_outflow),
          X=actualStream(port_b.Xi_outflow)));
    end if; // homotopyInitialization

  else // reverse flow not allowed
    TWatIn=Medium.temperature(Medium.setState_phX(p=port_a.p,
          h=inStream(port_a.h_outflow),
          X=inStream(port_a.Xi_outflow)));
    TWatOut=Medium.temperature(Medium.setState_phX(p=port_b.p,
          h=inStream(port_b.h_outflow),
          X=inStream(port_b.Xi_outflow)));
   end if;
   // For cp water, we use the inlet temperatures because the effect is small
   // for actual water temperature differences, and in case of Buildings.Media.Water,
   // cp is constant.
  cpWat = Medium.specificHeatCapacityCp(Medium.setState_phX(
    p=port_a.p,
    h=inStream(port_a.h_outflow),
    X=inStream(port_a.Xi_outflow)));

  // Determine the airflow based on fan speed signal
  mAir_flow = Buildings.Utilities.Math.Functions.spliceFunction(
    pos=y*mAir_flow_nominal,
    neg=fraFreCon*mAir_flow_nominal,
    x=y - yMin + yMin/20,
    deltax=yMin/20);
  FRAir = mAir_flow/mAir_flow_nominal;
  FRWat = m_flow/m_flow_nominal;

  // UA for equivalent fluid
  // Adjust UA
  UA_FAir =Buildings.Fluid.Utilities.extendedPolynomial(
    x=FRAir,
    c=UACor.cAirFra,
    xMin=UACor.FRAirMin,
    xMax=UACor.FRAirMax)
    "UA correction factor as function of air flow fraction";
  UA_FWat =Buildings.Fluid.Utilities.extendedPolynomial(
    x=FRWat,
    c=UACor.cWatFra,
    xMin=UACor.FRWatMin,
    xMax=UACor.FRWatMax)
    "UA correction factor as function of water flow fraction";
  UA_DifWB =Buildings.Fluid.Utilities.extendedPolynomial(
    x=TAirInWB_nominal - TAir,
    c=UACor.cDifWB,
    xMin=UACor.TDiffWBMin,
    xMax=UACor.TDiffWBMax)
    "UA correction factor as function of differential wet bulb temperature";
  corFac_FAir =Buildings.Utilities.Math.Functions.smoothHeaviside(
    x=FRAir - UACor.FRAirMin/4,
    delta=UACor.FRAirMin/4);
  corFac_FWat =Buildings.Utilities.Math.Functions.smoothHeaviside(
    x=FRWat - UACor.FRWatMin/4,
    delta=UACor.FRWatMin/4);

  UA = UA_nominal*UA_FAir*UA_FWat*UA_DifWB*corFac_FAir*corFac_FWat;

  UAe = UA*cpEqu/Buildings.Utilities.Psychrometrics.Constants.cpAir;

  // Capacity for air and water
  CAir_flow =abs(mAir_flow)*cpEqu;
  CWat_flow =abs(m_flow)*cpWat;
  CMin_flow =Buildings.Utilities.Math.Functions.smoothMin(
    CAir_flow,
    CWat_flow,
    delta*CMin_flow_nominal);

  // Calculate epsilon
  eps = Buildings.Fluid.HeatExchangers.BaseClasses.epsilon_C(
    UA=UAe,
    C1_flow=CAir_flow,
    C2_flow=CWat_flow,
    flowRegime=Integer(Buildings.Fluid.Types.HeatExchangerConfiguration.CounterFlow),
    CMin_flow_nominal=CMin_flow_nominal,
    CMax_flow_nominal=CMax_flow_nominal,
    delta=delta);
  // QMax_flow is maximum heat transfer into medium air: positive means heating
  QMax_flow = CMin_flow*(TWatIn - TAir);
  TApp=TWatOut-TAir;
  eps*QMax_flow =CAir_flow*(TAirOut - TAir);

  // Power consumption
  PFan = Buildings.Utilities.Math.Functions.spliceFunction(
        pos=cha.normalizedPower(per=fanRelPow, r_V=y, d=fanRelPowDer) * PFan_nominal,
        neg=0,
        x=y-yMin+yMin/20,
        deltax=yMin/20);

  cpEqu =
    Buildings.Fluid.HeatExchangers.CoolingTowers.BaseClasses.Functions.equivalentHeatCapacity(
      TIn=TAir,
      TOut=TAirOut);

  annotation (Icon(coordinateSystem(preserveAspectRatio=false), graphics={
        Text(
          extent={{-98,100},{-86,84}},
          lineColor={0,0,127},
          textString="y"),
        Text(
          extent={{-104,70},{-70,32}},
          lineColor={0,0,127},
          textString="TWB"),
        Rectangle(
          extent={{-100,81},{-70,78}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={0,0,127},
          fillPattern=FillPattern.Solid),
        Text(
          extent={{-54,6},{58,-114}},
          lineColor={255,255,255},
          fillColor={0,127,0},
          fillPattern=FillPattern.Solid,
          textString="Merkel"),
        Ellipse(
          extent={{-54,62},{0,50}},
          lineColor={255,255,255},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Ellipse(
          extent={{0,62},{54,50}},
          lineColor={255,255,255},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{78,82},{100,78}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={0,0,127},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{70,56},{82,52}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={0,0,127},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{78,54},{82,80}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={0,0,127},
          fillPattern=FillPattern.Solid),
        Text(
          extent={{64,114},{98,76}},
          lineColor={0,0,127},
          textString="PFan"),
        Rectangle(
          extent={{78,-60},{82,-4}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={0,0,127},
          fillPattern=FillPattern.Solid),
        Text(
          extent={{70,-58},{104,-96}},
          lineColor={0,0,127},
          textString="TLvg"),
        Rectangle(
          extent={{78,-58},{102,-62}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={0,0,127},
          fillPattern=FillPattern.Solid)}),
    Diagram(coordinateSystem(preserveAspectRatio=false)),
    Documentation(revisions="<html>
<ul>
<li>
January 10, 2020, by Michael Wetter:<br/>
Revised model, changed parameters to make model easier to use with design data.
</li>
<li>
October 22, 2019, by Yangyang Fu:<br/>
First implementation.
</li>
</ul>
</html>", info="<html>
<p>
Model for a steady-state or dynamic cooling tower with a variable speed fan
using Merkel's calculation method.
</p>
<h4>Thermal performance</h4>
<p>
To compute the thermal performance, this model takes as parameters the nominal water
mass flow rate, the water-to-air mass flow ratio at nominal condition,
the nominal inlet air wetbulb temperature,
and the nominal water inlet and outlet temperatures. Cooling tower performance is
modeled using the effectiveness-NTU relationships for various heat exchanger flow regimes.
</p>
<p>
The total heat transfer between the air and water entering the tower is computed based
on Merkel's theory. The fundamental basis for Merkel's theory is that the steady-state
total heat transfer is proportional to the difference between the enthalpy of air and
the enthalpy of air saturated at the wetted-surface temperature. This is represented
by
</p>
<p align=\"center\" style=\"font-style:italic;\">
 dQ&#775;<sub>total</sub> = UdA/c<sub>p</sub> (h<sub>s</sub> - h<sub>a</sub>),
</p>
<p>
where
<i>h<sub>s</sub></i> is the enthalpy of saturated air at the wetted-surface temperature,
<i>h<sub>a</sub></i> is the enthalpy of air in the free stream,
<i>c<sub>p</sub></i> is the specific heat of moist air,
<i>U</i> is the cooling tower overall heat transfer coefficient, and
<i>A</i> is the heat transfer surface area.
</p>
<p>
The model also treats the moist air as an equivalent gas with a mean specific heat
<i>c<sub>pe</sub></i> defined as
</p>
<p align=\"center\" style=\"font-style:italic;\">
 c<sub>pe</sub> = &Delta;h / &Delta;T<sub>wb</sub>,
</p>
<p>
where
<i>&Delta;h</i> and <i>&Delta;T<sub>wb</sub></i> are the enthalpy difference and
wetbulb temperature difference, respectively, between the entering and leaving air.
</p>
<p>
For off-design conditions, Merkel's theory is modified to include Sheier's
adjustment factors that change the current <i>UA</i> value. The three adjustment factors, based
on the current wetbulb temperature, air flow rates, and water flow rates, are used to calculate the
<i>UA</i> value as
</p>
<p align=\"center\" style=\"font-style:italic;\">
UA<sub>e</sub> = UA<sub>0</sub> &#183; f<sub>UA,wetbulb</sub> &#183; f<sub>UA,airflow</sub> &#183; f<sub>UA,waterflow</sub>,
</p>
<p>
where
<i>UA<sub>e</sub></i> and <i>UA<sub>0</sub></i> are the equivalent and design
overall heat transfer coefficent-area products, respectively.
The factors <i>f<sub>UA,wetbulb</sub></i>, <i>f<sub>UA,airflow</sub></i>, and <i>f<sub>UA,waterflow</sub></i>
adjust the current <i>UA</i> value for the current wetbulb temperature, air flow rate, and water
flow rate, respectively. These adjustment factors are third-order polynomial functions defined as
</p>
<p align=\"center\" style=\"font-style:italic;\">
f<sub>UA,x</sub> =
    c<sub>x,0</sub>&nbsp;
  + c<sub>x,1</sub> x
  + c<sub>x,2</sub> x<sup>2</sup>
  + c<sub>x,3</sub> x<sup>3</sup>,
</p>
<p>
where <i>x = {(T<sub>0,wetbulb</sub> - T<sub>wetbulb</sub>), &nbsp;
m&#775;<sub>air</sub> &frasl; m&#775;<sub>0,air</sub>, &nbsp;
m&#775;<sub>wat</sub> &frasl; m&#775;<sub>0,wat</sub>}
</i>
for the respective adjustment factor, and the
coefficients  <i>c<sub>x,0</sub></i>, <i>c<sub>x,1</sub></i>, <i>c<sub>x,2</sub></i>, and <i>c<sub>x,3</sub></i>
are the user-defined
values for the respective adjustment factor functions obtained from
<a href=\"modelica://Buildings.Fluid.HeatExchangers.CoolingTowers.Data.UAMerkel\">
Buildings.Fluid.HeatExchangers.CoolingTowers.Data.UAMerkel</a>.
By changing the parameter <code>UACor</code>, the
user can update the values in this record based on the performance characteristics of
their specific cooling tower.
</p>
<h4>Comparison with the cooling tower model of EnergyPlus</h4>
<p>
This model is similar to the model <code>CoolingTower:VariableSpeed:Merkel</code>
that is implemented in the EnergyPlus building energy simulation program version 8.9.0.
The main differences are:
</p>
<ol>
<li>
Not implemented are the basin heater power consumption and the make-up water usage.
</li>
<li>
The model has no built-in control to switch individual cells of the tower on or off.
To switch cells on or off, use multiple instances of this model, and use your own control
law to compute the input signal <i>y</i>.
</li>
</ol>
<h4>Assumptions</h4>
<p>
The following assumptions are made with Merkel's theory and this implementation:
</p>
<ol>
<li>
The moist air enthalpy is a function of wetbulb temperature only.
</li>
<li>
The wetted surface temperature is equal to the water temperature.
</li>
<li>
Cycle losses are not taken into account.
</li>
</ol>
<h4>References</h4>
<p><a href=\"https://energyplus.net/sites/all/modules/custom/nrel_custom/pdfs/pdfs_v8.9.0/EngineeringReference.pdf\">
EnergyPlus 8.9.0 Engineering Reference</a>, March 23, 2018. </p>
</html>"));
end Merkel;