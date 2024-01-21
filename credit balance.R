# Packages needed:
library(tidyverse) # for ggplot and dplyr and more!
library(MASS) # for glm models
library(ISLR) # for the data set
library(knitr) # for creating tables
library(pixiedust) # for creating tables with sprinkle (customizations)
library(kableExtra) # for creating tables with customizations
library(patchwork) # for multiple plots
library(caret) # for featurePlots

# log odds
p <- c(0.05, 0.10, 0.25, 0.50, 0.75, 0.9, 0.95 )
odds <- p/(1-p)
data.frame(p, odds = as.character(fractions(odds)),
           logit = log(odds))

credit <- Default # rename as to not overwrite original data set
head(credit)
str(credit)

fit1 <- glm(default ~ balance,data = credit, 
            family = binomial(link = "logit"), control = list(trace=TRUE))

summary(fit1)

ggplot(data = credit, aes(balance, y=as.numeric(default)-1))+
  geom_point(color="#fc8d59", shape=1, alpha = 0.5)+
  stat_smooth(method = "glm", se=FALSE, 
              method.args = list(family=binomial))+geom_line(y=1.0,
                                                             lty="dashed")+ geom_line(y=0,lty="dashed")+
  labs(x="Balance", y="Probability of Default", title = "Probability of Default as Credit Balance Changes")+
  theme_minimal() + theme(plot.title = element_text(hjust = 0.5))

dust(fit1) %>% sprinkle(col=2:4, round=3) %>%
  sprinkle(co=5,fn=quote(pval_string(value)))%>%
  sprinkle_colnames(term="Term",estimate="Estimate",std.error="SE",
                    statistic="Z-stat",
                    p.value="P-val")%>%
  kable()%>% kable_styling()

predict(fit1,newdata = data.frame(balance=1000),
        type = "response")  
predict(fit1,newdata = data.frame(balance=2000),
        type = "response")

preds <- predict(fit1,type = "response")
preds
# contrast for direction of stock (up or down)
contrasts(credit$default)

# prepare for confusion matrix
glm.pred <- ifelse(preds > 0.5, "Yes", "No")

# confusion table: this is training accuracy/error
table(glm.pred, credit$default) # row, column

(9625+100)/10000 # accuracy of predictions
(42+233)/10000 # error rate of predictions
100/(100+233) # sensitivity 
9625/(42+9625) #specificity

mean(glm.pred == credit$default)

# this time use student as the predictor
fit2 <- glm(default ~  factor(student), data = credit,
            family = binomial(link = "logit"),
            control = list(trace=TRUE))
summary(fit2)

dust(fit2) %>% sprinkle(col=2:4, round=3) %>%
  sprinkle(co=5, fn=quote(pvalString(value))) %>%
  sprinkle_colnames(term="Term", estimate="Estimate",
                    std.error="SE", statistic="Z-statistic",
                    p.value="P-value") %>%
  kable() %>%
  kable_styling()

predict(fit2,newdata = data.frame(student="Yes"),
        type = "response")

predict(fit2, newdata = data.frame(student="No"),
        type="response")
fit3 <- glm(default~balance+income+factor(student),
            data = credit,family = binomial(link = "logit"))

summary(fit3)

dust(fit3) %>% sprinkle(col=2:4, round=3) %>%
  sprinkle(co=5, fn=quote(pvalString(value))) %>%
  sprinkle_colnames(term="Term", estimate="Estimate",
                    std.error="SE", statistic="Z-statistic",
                    p.value="P-value") %>%
  kable() %>%
  kable_styling()

ggplot(data = credit,aes(student,balance))+
  geom_boxplot(lwd=0.75,color=c("blue", "orange"))+
  theme_minimal()

confint(fit3)

qqnorm(residuals(fit3))

# deviance is a goodness-of-fit statistic using sum of 
# squares of residuals, you can calculate it by taking
# the difference of likelihoods between the fitted model
# and the saturated model

diffDev <- fit3$null.deviance - fit3$deviance
diffDf <- fit3$df.null - fit3$df.residual

# difference in degrees of freedom
diffDf

# differences in deviances
round(diffDev,3) # small deviance

# compute p-val
round(1-pchisq(diffDev,diffDf),2)
# small p-val so the model has a better fit than null model

# since income not significant we remove it
fit4 <- glm(default~balance+factor(student),data = credit,
            family = binomial(link="logit"))
summary(fit4)

dust(fit4) %>% sprinkle(col=2:4, round=3) %>%
  sprinkle(co=5, fn=quote(pvalString(value))) %>%
  sprinkle_colnames(term="Term", estimate="Estimate",
                    std.error="SE", statistic="Z-statistic",
                    p.value="P-value") %>%
  kable() %>%
  kable_styling()

# assess the fit of the model using AIC not R^2
# fit1 (only balance)
# fit2 (only student)
# fit3 (balance,student,income)
# fit4 (balance,student)

AIC(fit1, fit2, fit3, fit4)