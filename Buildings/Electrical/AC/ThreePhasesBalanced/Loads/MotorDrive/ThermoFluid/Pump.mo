within Buildings.Electrical.AC.ThreePhasesBalanced.Loads.MotorDrive.ThermoFluid;
model Pump
  "Fan or pump with mechanical interface"
  extends Buildings.Fluid.Interfaces.PartialTwoPort(
  port_a(p(start=Medium.p_default)),
  port_b(p(start=Medium.p_default)));

  parameter Modelica.Units.SI.Inertia loaIne(min=0)=1 "Pump inertia";
  parameter Boolean addPowerToMedium=true
    "Set to false to avoid any power (=heat and flow work) being added to medium (may give simpler equations)";
  replaceable parameter Buildings.Fluid.Movers.Data.Generic per
    constrainedby Buildings.Fluid.Movers.Data.Generic
    "Record with performance data"
    annotation (choicesAllMatching=true,
      Placement(transformation(extent={{60,60},{80,80}})));

  Modelica.Units.SI.Torque tauPum "Pump torque";

  Modelica.Mechanics.Rotational.Interfaces.Flange_b shaft "Mechanical connector"
  annotation (Placement(transformation(extent={{-10,90},{10,110}})));
  Buildings.Fluid.Movers.SpeedControlled_Nrpm pum(
    redeclare final package Medium = Medium,
    final inputType=Buildings.Fluid.Types.InputType.Continuous,
    final addPowerToMedium=addPowerToMedium,
    per=per,
    final use_inputFilter=false)
    "Pump model"
    annotation (Placement(transformation(extent={{-10,-10},{10,10}})));
  Modelica.Mechanics.Rotational.Components.Inertia ine(J=loaIne,
    phi(fixed=true, start=0), w(fixed=true, start=0))
    "Pump inertia"
    annotation (
      Placement(transformation(
        extent={{10,-10},{-10,10}},
        rotation=-90,
        origin={0,80})));
  Modelica.Mechanics.Rotational.Sources.Torque tor "Torque source"
    annotation (Placement(transformation(extent={{-40,60},{-20,80}})));
  Modelica.Blocks.Sources.RealExpression tauSor(y=-tauPum)
    annotation (Placement(transformation(
        extent={{10,10},{-10,-10}},
        rotation=180,
        origin={-70,90})));
  Modelica.Mechanics.Rotational.Sensors.SpeedSensor spe "Rotation speed in rad/s"
    annotation (Placement(transformation(extent={{10,50},
            {30,70}})));
  Modelica.Blocks.Math.UnitConversions.To_rpm to_rpm
    annotation (Placement(transformation(extent={{30,20},{10,40}})));
  Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a heatPort
    "Heat dissipation to environment"
    annotation (Placement(transformation(extent={{-70,-110},{-50,-90}}),
        iconTransformation(extent={{-10,-78},{10,-58}})));
  Modelica.Blocks.Interfaces.RealOutput P(quantity="Power", final unit="W")
    "Electrical power consumed"
    annotation (Placement(transformation(extent={{100,80},{120,100}}),
        iconTransformation(extent={{100,80},{120,100}})));
  Modelica.Blocks.Interfaces.RealOutput y_actual(final unit="1")
    "Actual normalised pump speed that is used for computations"
    annotation (Placement(transformation(extent={{100,60},{120,80}}),
        iconTransformation(extent={{100,60},{120,80}})));

equation
  pum.P = tauPum*Buildings.Utilities.Math.Functions.smoothMax(spe.w,1e-6,1e-8);

  connect(port_a, pum.port_a)
    annotation (Line(points={{-100,0},{-10,0}}, color={0,127,255}));
  connect(pum.port_b, port_b)
    annotation (Line(points={{10,0},{100,0}}, color={0,127,255}));
  connect(pum.heatPort, heatPort) annotation (Line(points={{0,-6.8},{0,-70},{
          -60,-70},{-60,-100}}, color={191,0,0}));
  connect(shaft, ine.flange_b) annotation (Line(points={{0,100},{0,90}}, color={0,0,0}));
  connect(tor.flange, ine.flange_a)
    annotation (Line(points={{-20,70},{0,70}}, color={0,0,0}));
  connect(tauSor.y, tor.tau) annotation (Line(points={{-59,90},{-50,90},{-50,70},
          {-42,70}}, color={0,0,127}));
  connect(ine.flange_a, spe.flange) annotation (Line(points={{0,70},{0,60},{10,60}}, color={0,0,0}));
  connect(spe.w,to_rpm. u) annotation (Line(points={{31,60},{40,60},{40,30},{32,
          30}}, color={0,0,127}));
  connect(to_rpm.y, pum.Nrpm)
    annotation (Line(points={{9,30},{0,30},{0,12}}, color={0,0,127}));
  connect(pum.P, P) annotation (Line(points={{11,9},{90,9},{90,90},{110,90}},
        color={0,0,127}));
  connect(pum.y_actual, y_actual) annotation (Line(points={{11,7},{92,7},{92,70},
          {110,70}}, color={0,0,127}));
  annotation (defaultComponentName="pum",
    Icon(coordinateSystem(preserveAspectRatio=true,  extent={{-100,-100},{100,
            100}}), graphics={
        Rectangle(
          extent={{-100,16},{100,-16}},
          lineColor={0,0,0},
          fillColor={0,127,255},
          fillPattern=FillPattern.HorizontalCylinder),
        Rectangle(
          visible=use_inputFilter,
          extent={{-10,44},{10,100}},
          lineColor={0,0,0},
          fillColor={135,135,135},
          fillPattern=FillPattern.Solid),
        Ellipse(
          extent={{-58,58},{58,-58}},
          lineColor={0,0,0},
          fillPattern=FillPattern.Sphere,
          fillColor={0,100,199}),
        Polygon(
          points={{0,50},{0,-50},{54,0},{0,50}},
          lineColor={0,0,0},
          pattern=LinePattern.None,
          fillPattern=FillPattern.HorizontalCylinder,
          fillColor={255,255,255}),
        Ellipse(
          extent={{4,16},{36,-16}},
          lineColor={0,0,0},
          fillPattern=FillPattern.Sphere,
          visible=energyDynamics <> Modelica.Fluid.Types.Dynamics.SteadyState,
          fillColor={0,100,199}),
        Line(
          points={{0,90},{100,90}},
          color={0,0,0},
          smooth=Smooth.None),
        Line(
          points={{0,70},{100,70}},
          color={0,0,0},
          smooth=Smooth.None),
        Line(
          points={{0,90},{0,70}},
          color={0,0,0},
          smooth=Smooth.None),
        Text(extent={{50,104},{100,90}},
          textColor={0,0,127},
          textString="P"),
        Text(extent={{50,84},{100,70}},
          textColor={0,0,127},
          textString="y_actual")}),
    Documentation(info="<html>
    <p>This model describes a fan or pump with mechanical imterface, it is use the <a href=\"modelica://Buildings.Fluid.Movers.SpeedControlled_Nrpm\">Buildings.Fluid.Movers.SpeedControlled_Nrpm</a> as a base model. 
    </p>
    <p>The governing equation of this implementation is based on the relationship between the power and torque of the rotating object, which is represented as follow:
<p align=\"center\" style=\"font-style:italic;\">P&nbsp;=&nbsp;tau&nbsp;*&nbsp;W</p>
<p>Where, the <i>P</i> is power [W], <i>tau</i> is torque [N.m], and <i>W</i> is angular velocity [rad/s].
</p>
</html>",
      revisions="<html>
<ul>
<li>September 15, 2021,
    by Mingzhe Liu:<br/>
    Refactored implementation to integrate inertia into the model.
</li>
<li>6 March 2019, 
    by Yangyang Fu:<br/>
      First implementation.</li>
</ul>
</html>"));
end Pump;