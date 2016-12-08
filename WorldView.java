import javax.swing.*;
import javax.swing.border.*;
import javax.swing.table.*;
import java.awt.*;
import java.awt.event.*;

import java.text.BreakIterator;

import java.util.Locale;
import java.util.ResourceBundle;
import java.util.MissingResourceException;

import CLIPSJNI.*;

class WorldView implements ActionListener {
   JLabel displayLabel;
   JButton nextButton;
   JButton prevButton;
   JButton restartButton;
   JPanel choicesPanel;
   ButtonGroup choicesButtons;
   ResourceBundle resources;

   Environment clips;
   boolean isExecuting = false;
   Thread executionThread;

   public static void main(String args[]) {
      SwingUtilities.invokeLater(
        new Runnable() {
          public void run() {
            new WorldView();
          }
        }
      );
   }

   WorldView() {
      try {
         resources = ResourceBundle.getBundle("resources.worldViewResources",Locale.getDefault());
      }
      catch (MissingResourceException mre) {
         mre.printStackTrace();
         return;
      }

      JFrame jfrm = createContainer(resources);
      initiateFrameProperties(jfrm);
      JPanel displayPanel = new JPanel();
      addLabelToPanel(displayPanel);
      choicesPanel = new JPanel();
      choicesButtons = new ButtonGroup();
      JPanel buttonPanel = createButtonsPanel();

      addPanelToFrame(jfrm, displayPanel);
      addPanelToFrame(jfrm, choicesPanel);
      addPanelToFrame(jfrm, buttonPanel);

      loadProgram();
      runProgram();

      setFrameVisible(jfrm);
   }

   public void runProgram() {
     Runnable runThread = new Runnable() {
       public void run() {
         clips.run();

         SwingUtilities.invokeLater(
            new Runnable() {
              public void run() {
                try {
                  nextUIState();
                }
                catch (Exception e) {
                  e.printStackTrace();
                }
              }
            });
       }
     };

     isExecuting = true;
     executionThread = new Thread(runThread);
     executionThread.start();
   }

   private void nextUIState() throws Exception {
     String evalStr = getStateList();
     String currentID = getCurrentID(evalStr);
     evalStr = getCurrentUIstate(currentID);
     PrimitiveValue fv = clips.eval(evalStr).get(0);

     determineButtonsStates(fv);

     clearChoices();
     choicesButtons = new ButtonGroup();

     PrimitiveValue validAnswers = findFactSlot(fv, "valid-answers");
     String selected = findFactSlot(fv, "response").toString();
     displayButtons(validAnswers, selected);

     setLabelToDisplayText(fv);

     stopExecuting();
   }

   public void actionPerformed(ActionEvent ae) {
     try {
       onActionPerformed(ae);
     }
     catch (Exception e) {
       e.printStackTrace();
     }
   }

   private void handleButtons(ActionEvent ae, String currentID) throws Exception {
      if (ae.getActionCommand().equals("Next")) {
        if (choicesButtons.getButtonCount() == 0)
          clips.assertString("(next " + currentID + ")");
        else
          clips.assertString("(next " + currentID + " " + choicesButtons.getSelection().getActionCommand() + ")");

        runProgram();
      } else if (ae.getActionCommand().equals("Restart")) {
        clips.reset();
        runProgram();
      } else if (ae.getActionCommand().equals("Prev")) {
        clips.assertString("(prev " + currentID + ")");
        runProgram();
      }
   }

   private void onActionPerformed(ActionEvent ae) throws Exception {
     if (isExecuting) return;

     String evalStr = getStateList();
     String currentID = getCurrentID(evalStr);

     handleButtons(ae, currentID);
   }

   private void wrapLabelText(JLabel label, String text) {
     FontMetrics fm = label.getFontMetrics(label.getFont());
     Container container = label.getParent();
     int containerWidth = container.getWidth();
     int textWidth = SwingUtilities.computeStringWidth(fm,text);
     int desiredWidth;

     if (textWidth <= containerWidth)
       desiredWidth = containerWidth;
     else {
       int lines = (int) ((textWidth + containerWidth) / containerWidth);
       desiredWidth = (int) (textWidth / lines);
     }

     BreakIterator boundary = BreakIterator.getWordInstance();
     boundary.setText(text);

     StringBuffer trial = new StringBuffer();
     StringBuffer real = new StringBuffer("<html><center>");

     int start = boundary.first();
     for (int end = boundary.next(); end != BreakIterator.DONE; start = end, end = boundary.next()) {
        String word = text.substring(start,end);
        trial.append(word);
        int trialWidth = SwingUtilities.computeStringWidth(fm,trial.toString());
        if (trialWidth > containerWidth) {
           trial = new StringBuffer(word);
           real.append("<br>");
           real.append(word);
        } else if (trialWidth > desiredWidth) {
           trial = new StringBuffer("");
           real.append(word);
           real.append("<br>");
        } else
           real.append(word);
     }

     real.append("</html>");
     label.setText(real.toString());
   }

     private JFrame createContainer(ResourceBundle resources) {
       return new JFrame(resources.getString("Title"));
     }

     private void initiateFrameProperties(JFrame frame) {
       frame.getContentPane().setLayout(new GridLayout(3,1));
       frame.setSize(600,300);
       frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
     }

     private void addLabelToPanel(JPanel panel) {
       displayLabel = new JLabel();
       panel.add(displayLabel);
     }

     private JPanel createButtonsPanel() {
       JPanel buttonPanel = new JPanel();
       prevButton = new JButton(resources.getString("Prev"));
       prevButton.setActionCommand("Prev");
       buttonPanel.add(prevButton);
       prevButton.addActionListener(this);

       nextButton = new JButton(resources.getString("Next"));
       nextButton.setActionCommand("Next");
       buttonPanel.add(nextButton);
       nextButton.addActionListener(this);

       restartButton = new JButton(resources.getString("Restart"));
       restartButton.setActionCommand("Restart");
       buttonPanel.add(restartButton);
       restartButton.addActionListener(this);

       return buttonPanel;
     }

     private void loadProgram() {
       clips = new Environment();

       clips.load("WorldView.clp");
       clips.reset();
     }

     private void addPanelToFrame(JFrame frame, JPanel panel) {
       frame.getContentPane().add(panel);
     }

     private void setFrameVisible(JFrame frame) {
       frame.setVisible(true);
     }

     private String getStateList() throws Exception {
       return "(find-all-facts ((?f state-list)) TRUE)";
     }

     private String getCurrentID(String evalStr) throws Exception {
       return clips.eval(evalStr).get(0).getFactSlot("current").toString();
     }

     private String getCurrentUIstate(String currentID) {
       return "(find-all-facts ((?f UI-state)) " + "(eq ?f:id " + currentID + "))";
     }

     private void determineButtonsStates(PrimitiveValue fv) throws Exception {
       if (isState(fv, "final")) {
         setButtonVisibility(prevButton, true);
         setButtonVisibility(nextButton, false);
         setButtonVisibility(restartButton, true);
       } else if (isState(fv, "initial")) {
         setButtonVisibility(prevButton, false);
         setButtonVisibility(nextButton, true);
         setButtonVisibility(restartButton, false);
       } else if (isState(fv, "temp")) {
         setButtonVisibility(prevButton, true);
         setButtonVisibility(nextButton, true);
         setButtonVisibility(restartButton, true);
       } else {
         setButtonVisibility(prevButton, true);
         setButtonVisibility(nextButton, true);
         setButtonVisibility(restartButton, false);
       }
     }

     private boolean isState(PrimitiveValue fv, String stateName) throws Exception {
       return fv.getFactSlot("state").toString().equals(stateName);
     }

     private void setButtonVisibility(JButton button, boolean visible) {
       button.setVisible(visible);
     }

     private void clearChoices() {
       choicesPanel.removeAll();
     }

     private PrimitiveValue findFactSlot(PrimitiveValue fv, String name) throws Exception {
       PrimitiveValue pv = fv.getFactSlot(name);
       return pv;
     }

     private void displayButtons(PrimitiveValue pv, String selected) throws Exception {
      for (int i = 0; i < pv.size(); i++) {
         PrimitiveValue bv = pv.get(i);
         JRadioButton rButton;

         if (bv.toString().equals(selected))
            { rButton = new JRadioButton(resources.getString(bv.toString()),true); }
         else
            { rButton = new JRadioButton(resources.getString(bv.toString()),false); }

         rButton.setActionCommand(bv.toString());
         choicesPanel.add(rButton);
         choicesButtons.add(rButton);
      }

        choicesPanel.repaint();
     }

     private void setLabelToDisplayText(PrimitiveValue fv) throws Exception {
       String theText = resources.getString(findFactSlot(fv, "display").symbolValue());

       wrapLabelText(displayLabel, theText);
     }

     private void stopExecuting() {
       executionThread = null;
       isExecuting = false;
     }
}
